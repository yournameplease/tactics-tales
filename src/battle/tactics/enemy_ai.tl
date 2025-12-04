require("src/debug")

require("src/menu/menu_manager")
require("src/battle/tactics/battle_unit")
require("src/battle/tile_manager")
require("src/battle/battle_manager")
require("src/battle/tactics/tactics_engine")
require("src/systems/event_bus")
require("src/systems/tasks")
require("src/battle/battle_state")

--[[
AI Mk 1:
- perform full dijkstra on tiles, with ancestor references
- if enemy in range, look at all tiles within attack range
- - pick one at random
- else
- - pick nearest  enemy, move as close as possible
]]

global record EnemyAIEngine
    battle_manager: BattleManager
    battle_state: BattleState
    tactics_engine: TacticsEngine
    event_bus: EventBus
    task_manager: TaskManager
    tile_manager: TileManager
end

local record AttackOption
    destination: TilePoint
    target: BattleUnit
end

local record MovementOption
    destination: TilePoint
end

function EnemyAIEngine:compute_enemy_ai(unit: BattleUnit)
    local tile_manager = self.battle_manager.tile_manager -- TODO: global state
    local all_tile_costs = tile_manager:calculate_all_tile_costs(unit.tile.x, unit.tile.y, unit.side, 999) 

    local enemies = self.tactics_engine.battle_state:get_units(unit_is_player)

    local potential_attacks: {AttackOption} = {}
    local deep_moves: {MovementOption} = {}

    for _,e in ipairs(enemies) do
        local min_range, max_range = unit.character:get_weapon_range()
        local tiles_in_range = self.tactics_engine:find_tiles_with_distance_from_tile(e.tile.x, e.tile.y, min_range, max_range)
        tiles_in_range:foreachpoint(function(tile: TilePoint, in_range: boolean)
            if in_range then
                local shortest_path_tile = all_tile_costs:get_point(tile) -- if could calculate
                if shortest_path_tile ~= nil then
                    if shortest_path_tile.cost <= unit.character.stats.movement then
                        if self.battle_state:tile_is_legal_destination(unit, tile ) then
                            add(potential_attacks, { destination = tile, target = e})
                        end
                    else
                        add(deep_moves, { destination = tile })
                    end
                end
            end
        end)
    end

    if #potential_attacks > 0 then
        local choice = potential_attacks[1]

        local destination = choice.destination
        local path = tile_manager:get_path_to_tile(all_tile_costs, destination)

        local action_ctx: MenuContext = {
            acting_unit = { unit = unit},
            destination = { point = destination, path = path},
            target_unit = { unit = choice.target }
        }
        LOG.info(unit.id .. " will attack "..choice.target.id)
        self.event_bus:emit("MOVE_AND_ATTACK", action_ctx)
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
            or not self.battle_state:tile_is_legal_destination(unit, point) do
            point = all_tile_costs:get_point(point).prev
        end

        local path = tile_manager:get_path_to_tile(all_tile_costs, point)

        local action_ctx = {
            acting_unit = { unit = unit },
            destination = { point = point, path = path }
        }
        LOG.info(unit.id .. " will move to "..point.x..","..point.y)
        self.event_bus:emit("MOVE_AND_WAIT", action_ctx)
    else
        LOG.warn("WARN: No valid moves for "..unit.id.. "!")
    end
end

function EnemyAIEngine:handle_enemy_turn()
    self.task_manager:start_routine(function()
        local enemies = self.battle_state:get_units(unit_is_enemy)

        for _,enemy in ipairs(enemies) do
            self:compute_enemy_ai(enemy)
            while self.tactics_engine:is_blocked() do
                yield()
            end
        end

        self.event_bus:emit("TACTICS_END_ENEMY_TURN")
    end)
end

function EnemyAIEngine.new(
    battle_manager: BattleManager,
    battle_state: BattleState,
    tactics_engine: TacticsEngine,
    event_bus: EventBus,
    task_manager: TaskManager,
    tile_manager: TileManager
): EnemyAIEngine
    local self: EnemyAIEngine = setmetatable({}, { __index = EnemyAIEngine })

    self.battle_manager = battle_manager
    self.battle_state = battle_state
    self.tactics_engine = tactics_engine
    self.event_bus = event_bus
    self.task_manager = task_manager
    self.tile_manager = tile_manager

    self.event_bus:on("TACTICS_BEGIN_ENEMY_TURN", function() self:handle_enemy_turn() end)
    return self
end

return EnemyAIEngine
