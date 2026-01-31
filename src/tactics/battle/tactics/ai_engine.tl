local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local lists = require("src.tactics.util.lists")
local character = require("src.tactics.character.object.character")
local point = require("src.tactics.util.point")
local Point = point.Point
local pathfinding = require("src.tactics.battle.pathfinding")
local tactics_engine = require("src.tactics.battle.tactics.tactics_engine")
local tasks = require("src.tactics.systems.tasks")
local bm = require("src.tactics.battle.battle_map")

--[[
AI Mk 1:
- perform full dijkstra on tiles, with ancestor references
- if enemy in range, look at all tiles within attack range
- - pick one at random
- else
- - pick nearest  enemy, move as close as possible
]]

local record AIEngine
    battle_map: bm.BattleMap
    tactics_engine: tactics_engine.TacticsEngine
    task_manager: tasks.TaskManager
end

local ai_engine = {
    AIEngine = AIEngine,
}

local record MovementOption
    destination: Point
    target: BattleUnit -- nillable
end

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
    
    local shallow_actions: {MovementOption} = {}
    local deep_actions: {MovementOption} = {}

    local targeting = unit.character:get_weapon_targeting()
        
    if shallow_move_limit > 0 then
        all_tile_costs:foreachpoint(function(p: Point, cost: pathfinding.ShortestPathEntry)
            if cost ~= nil
                and cost.cost <= shallow_move_limit
                and self.battle_map:tile_is_legal_destination(unit, p)
            then
                -- one_turn move, can attack
                local targets = self.battle_map:get_units(function(u: BattleUnit): boolean
                    return should_target(u) and targeting.is_target_valid(p, u.tile, self.battle_map)
                end)
                for _,t in ipairs(targets) do
                    pt.add(shallow_actions, {
                        destination = p,
                        target = t,
                    })
                end
            end
        end)
    end
    if #shallow_actions == 0 then
        all_tile_costs:foreachpoint(function(p: Point, cost: pathfinding.ShortestPathEntry)
            if cost ~= nil
                and cost.cost > shallow_move_limit
                and self.battle_map:tile_is_legal_destination(unit, p)
            then
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

    if #shallow_actions > 0 then
        local choice = shallow_actions[1]

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
