---@brief
--- The AI engine for controlling non-player units in battle.
--- It analyzes the game state to determine and execute optimal actions,
--- such as moving and attacking targets.

local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local lists = require("src.tactics.util.lists")
local character = require("src.tactics.character.object.character")
local combat_calculator = require("src.tactics.battle.combat.combat_calculator")
local point = require("src.tactics.util.point")
local Point = point.Point
local pathfinding = require("src.tactics.battle.pathfinding")
local tactics_engine = require("src.tactics.battle.tactics.tactics_engine")
local tasks = require("src.tactics.systems.tasks")
local bm = require("src.tactics.battle.battle_map")

local record AIEngine
    battle_map: bm.BattleMap
    tactics_engine: tactics_engine.TacticsEngine
    task_manager: tasks.TaskManager
end

local ai_engine = {
    AIEngine = AIEngine,
}

local record ShallowMovementOption
    destination: Point
    target: BattleUnit -- nillable
    expected_kill: boolean
    expected_self_kill: boolean
    expected_counterattack: boolean
    expected_damage: integer 
    expected_self_damage: integer 
    ally_score: integer
end

local function better_shallow_movement_option(a: ShallowMovementOption, b: ShallowMovementOption): boolean
    if a == nil then
        return false 
    end
    if b == nil then
        return true
    end
    if a.expected_kill ~= b.expected_kill then
        return a.expected_kill
    end
    if a.expected_self_kill ~= b.expected_self_kill then
        return not a.expected_self_kill
    end
    if a.expected_counterattack ~= b.expected_counterattack then
        return not a.expected_counterattack
    end
    if a.expected_damage ~= b.expected_damage then
        return a.expected_damage > b.expected_damage
    end
    if a.expected_self_damage ~= b.expected_self_damage then
        return a.expected_self_damage < b.expected_self_damage
    end

    return a.ally_score > b.ally_score
end

local record DeepMovementOption
    destination: Point
    target: BattleUnit -- nillable
end

---@desc
--- Computes and executes the best action for a given AI-controlled unit.
--- The AI first checks for targets it can attack within a single move.
--- If none are found, it identifies the closest target it could attack
--- with extended movement and moves as close as possible to it.
--- If no actions are possible, the unit will wait.
function AIEngine:compute_unit_ai(unit: BattleUnit)
    local ai = unit.unit_ai

    local max_move: integer
    local shallow_move_limit = unit.character.stats.movement
    if ai.move == "zero" then
        max_move = 0
        shallow_move_limit = 0
    elseif ai.move == "one" then
        max_move = unit.character.stats.movement
    elseif ai.move == "two" then
        max_move = unit.character.stats.movement * 2
    elseif ai.move == "infinity" then
        max_move = 999
    else
        unexpected(ai.move)
    end

    local should_target = function(u: BattleUnit): boolean
        if ai.exclude_tags ~= nil then
            for _,t in ipairs(ai.exclude_tags) do
                if u:has_tag(t) then return false end
            end
        end
        return lists.contains(ai.target_sides, u.side)
    end
        
    local all_tile_costs = pathfinding.calculate_all_tile_costs(self.battle_map, unit.tile.x, unit.tile.y, unit.side, max_move) 
    
    local best_shallow_action: ShallowMovementOption = nil
    local deep_actions: {DeepMovementOption} = {}

    local targeting = unit.character:get_weapon_targeting()
        
    all_tile_costs:foreachpoint(function(p: Point, cost: pathfinding.ShortestPathEntry)
        if cost ~= nil
            and cost.cost <= shallow_move_limit
            and self.battle_map:tile_is_legal_destination(unit, p)
        then
            local ally_score: integer = nil
            -- one_turn move, can attack
            local targets = self.battle_map:get_units(function(u: BattleUnit): boolean
                return should_target(u) and targeting.is_target_valid(p, u.tile, self.battle_map)
            end)
            for _,t in ipairs(targets) do
                if not ally_score then
                    ally_score = 0
                    for x = -2, 2 do
                        for y = -2, 2 do
                            if self.battle_map:tile_is_in_map(point.of(x, y)) then
                                local u = self.battle_map:get_at_tile(point.of(x, y))
                                if u and u.side == unit.side then
                                    ally_score = ally_score + 1
                                end
                            end
                        end
                    end
                end
                
                local combat_result = combat_calculator.preview_combat(
                    unit,
                    t,
                    p,
                    self.battle_map
                )

                local shallow_action: ShallowMovementOption = {
                    destination = p,
                    target = t,
                    expected_kill = combat_result.possible_kill,
                    expected_self_kill = combat_result.possible_self_kill,
                    expected_counterattack = combat_result.possible_counterattack,
                    expected_damage =  combat_result.expected_damage,
                    expected_self_damage =  combat_result.expected_self_damage,
                    ally_score = ally_score, -- todo: count nearby allies
                }

                if better_shallow_movement_option(shallow_action, best_shallow_action) then
                    best_shallow_action = shallow_action
                end
            end
        end
    end)
    if best_shallow_action == nil then
        all_tile_costs:foreachpoint(function(p: Point, cost: pathfinding.ShortestPathEntry)
            if cost ~= nil then
                -- one_turn move, can attack
                local targets = self.battle_map:get_units(function(u: BattleUnit): boolean
                    return should_target(u) and targeting.is_target_valid(p, u.tile, self.battle_map)
                end)
                for _,t in ipairs(targets) do
                    pt.add(deep_actions, {
                        destination = p,
                        target = t,
                    })
                end
            end
        end)
    end

    if best_shallow_action then
        local choice = best_shallow_action

        local destination = choice.destination
        local path = pathfinding.get_path_to_tile(all_tile_costs, destination)

        log.info(unit.id .. " will attack "..choice.target.id)
        self.tactics_engine:handle_move_and_attack(
            unit,
            destination,
            path,
            choice.target
        )
    elseif #deep_actions > 0 then
        local min_cost_deep_action = deep_actions[1]
        local min_cost = 999
        for _,deep_action in ipairs(deep_actions) do
            if all_tile_costs:get_point(deep_action.destination).cost < min_cost then
                min_cost = all_tile_costs:get_point(deep_action.destination).cost
                min_cost_deep_action = deep_action
            end
        end
        -- follow until first tile in range
        local current_point = min_cost_deep_action.destination
        while all_tile_costs:get_point(current_point).cost > unit.character.stats.movement
            or not self.battle_map:tile_is_legal_destination(unit, current_point) do
            current_point = all_tile_costs:get_point(current_point).prev
        end

        local path = pathfinding.get_path_to_tile(all_tile_costs, current_point)

        log.info(unit.id .. " will move to "..current_point.x..","..current_point.y)
        self.tactics_engine:handle_move_and_wait(
            unit,
            current_point,
            path
        )
    else
        log.info(unit.id.." will not act.")
        self.tactics_engine:handle_move_and_wait(
            unit,
            unit.tile,
            {}
        )
    end
end

function AIEngine:handle_one_unit_action(side: character.Side)
    self.task_manager:start_routine(function()
        local to_act = function(u: BattleUnit): boolean
            return u.side == side and not u.has_acted
        end
        local enemies_to_act = self.battle_map
            :get_units(to_act)
        assert(#enemies_to_act > 0)

        self:compute_unit_ai(enemies_to_act[1])
        while self.tactics_engine:is_blocked() do
            pt.yield()
        end

    end)
end

function ai_engine.new(
    map: bm.BattleMap,
    tactics: tactics_engine.TacticsEngine,
    task_manager: tasks.TaskManager
): AIEngine
    local self: AIEngine = setmetatable({
    }, { __index = AIEngine })

    self.battle_map = map
    self.tactics_engine = tactics
    self.task_manager = task_manager
    return self
end

return ai_engine
