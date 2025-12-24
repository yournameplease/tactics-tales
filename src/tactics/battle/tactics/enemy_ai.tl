require("src/tactics/debug")

require("src/tactics/menu/menu_manager")
require("src/tactics/battle/tactics/battle_unit")
local pathfinding = require("src/tactics/battle/pathfinding")
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")
require("src/tactics/systems/event_bus")
local event_writer = require("src/tactics/systems/event_bus/event_writer")
require("src/tactics/systems/tasks")
require("src/tactics/battle/battle_map")

--[[
AI Mk 1:
- perform full dijkstra on tiles, with ancestor references
- if enemy in range, look at all tiles within attack range
- - pick one at random
- else
- - pick nearest  enemy, move as close as possible
]]

local record EnemyAIEngine
    battle_map: BattleMap
    tactics_engine: tactics_engine.TacticsEngine
    event_writer: event_writer.EventWriter
    task_manager: TaskManager
end

local enemy_ai_engine = {
    EnemyAIEngine = EnemyAIEngine,
}

local record AttackOption
    destination: Point
    target: BattleUnit
end

local record MovementOption
    destination: Point
end

function EnemyAIEngine:compute_enemy_ai(unit: BattleUnit)
    local ai = unit.unit_ai

    local max_move: integer
    if ai.move == "zero" then
        max_move = 0
    elseif ai.move == "one" then
        max_move = unit.character.stats.movement
    elseif ai.move == "two" then
        max_move = unit.character.stats.movement * 2
    elseif ai.move == "infinity" then
        max_move = 999
    else
        error()
    end
        
    local all_tile_costs = pathfinding.calculate_all_tile_costs(self.battle_map, unit.tile.x, unit.tile.y, unit.side, max_move) 
    
    local enemies = self.battle_map:get_units(function(u: BattleUnit): boolean return u:is_player() end)

    local potential_attacks: {AttackOption} = {}
    local deep_moves: {MovementOption} = {}

    for _,e in ipairs(enemies) do
        local min_range, max_range = unit.character:get_weapon_range()
        local tiles_in_range = self.tactics_engine:find_tiles_with_distance_from_tile(e.tile.x, e.tile.y, min_range, max_range)
        tiles_in_range:foreachpoint(function(tile: Point, in_range: boolean)
            if in_range then
                local shortest_path_tile = all_tile_costs:get_point(tile) -- if could calculate
                if shortest_path_tile ~= nil then
                    if shortest_path_tile.cost <= unit.character.stats.movement then
                        if self.battle_map:tile_is_legal_destination(unit, tile ) then
                            pt.add(potential_attacks, { destination = tile, target = e})
                        end
                    else
                        pt.add(deep_moves, { destination = tile })
                    end
                end
            end
        end)
    end

    if #potential_attacks > 0 then
        local choice = potential_attacks[1]

        local destination = choice.destination
        local path = pathfinding.get_path_to_tile(all_tile_costs, destination)

        local action_ctx: MenuContext = {
            acting_unit = { unit = unit},
            destination = { point = destination, path = path},
            target_unit = { unit = choice.target }
        }
        LOG.info(unit.id .. " will attack "..choice.target.id)
        self.event_writer:emit("MOVE_AND_ATTACK", action_ctx)
    elseif #deep_moves > 0 then
        local min_cost_deep_move = deep_moves[1]
        local min_cost = 999
        for _,deep_move in ipairs(deep_moves) do
            if all_tile_costs:get_point(deep_move.destination).cost < min_cost then
                min_cost = all_tile_costs:get_point(deep_move.destination).cost
                min_cost_deep_move = deep_move
            end
        end
        -- follow until first tile in range
        local point = min_cost_deep_move.destination
        while all_tile_costs:get_point(point).cost > unit.character.stats.movement
            or not self.battle_map:tile_is_legal_destination(unit, point) do
            point = all_tile_costs:get_point(point).prev
        end

        local path = pathfinding.get_path_to_tile(all_tile_costs, point)

        local action_ctx = {
            acting_unit = { unit = unit },
            destination = { point = point, path = path }
        }
        LOG.info(unit.id .. " will move to "..point.x..","..point.y)
        self.event_writer:emit("MOVE_AND_WAIT", action_ctx)
    else
        LOG.warn("WARN: No valid moves for "..unit.id.. "!")
    end
end

function EnemyAIEngine:handle_enemy_turn()
    self.task_manager:start_routine(function()
        local enemies = self.battle_map:get_units(function(u: BattleUnit): boolean return u:is_enemy() end)

        for _,enemy in ipairs(enemies) do
            self:compute_enemy_ai(enemy)
            while self.tactics_engine:is_blocked() do
                pt.yield()
            end
        end

        self.event_writer:emit("TACTICS_FINISH_ENEMY_ACTIONS", {})
    end)
end

function enemy_ai_engine.new(
    battle_map: BattleMap,
    tactics: tactics_engine.TacticsEngine,
    bus: EventBus,
    task_manager: TaskManager
): EnemyAIEngine
    local self: EnemyAIEngine = setmetatable({
    }, { __index = EnemyAIEngine })

    self.battle_map = battle_map
    self.tactics_engine = tactics
    self.event_writer = event_writer.new(bus)
    self.task_manager = task_manager
    return self
end

return enemy_ai_engine
