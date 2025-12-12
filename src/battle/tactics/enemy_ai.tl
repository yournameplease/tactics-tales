require("src/debug")

require("src/menu/menu_manager")
require("src/battle/tactics/battle_unit")
local Pathfinding = require("src/battle/pathfinding")
require("src/battle/tactics/tactics_engine")
require("src/systems/event_bus")
require("src/systems/tasks")
require("src/battle/battle_map")
require("src/systems/service")
require("src/battle/battle_context")
require("src/systems/service/game_service_bundle")

--[[
AI Mk 1:
- perform full dijkstra on tiles, with ancestor references
- if enemy in range, look at all tiles within attack range
- - pick one at random
- else
- - pick nearest  enemy, move as close as possible
]]

global record EnemyAIEngine
    ctx: BattleContext
end

local record AttackOption
    destination: TilePoint
    target: BattleUnit
end

local record MovementOption
    destination: TilePoint
end

function EnemyAIEngine:compute_enemy_ai(unit: BattleUnit)
    local all_tile_costs = Pathfinding.calculate_all_tile_costs(self.ctx.battle_map, unit.tile.x, unit.tile.y, unit.side, 999) 

    local enemies = self.ctx.battle_map:get_units(unit_is_player)

    local potential_attacks: {AttackOption} = {}
    local deep_moves: {MovementOption} = {}

    for _,e in ipairs(enemies) do
        local min_range, max_range = unit.character:get_weapon_range()
        local tiles_in_range = self.ctx.tactics_engine:find_tiles_with_distance_from_tile(e.tile.x, e.tile.y, min_range, max_range)
        tiles_in_range:foreachpoint(function(tile: TilePoint, in_range: boolean)
            if in_range then
                local shortest_path_tile = all_tile_costs:get_point(tile) -- if could calculate
                if shortest_path_tile ~= nil then
                    if shortest_path_tile.cost <= unit.character.stats.movement then
                        if self.ctx.battle_map:tile_is_legal_destination(unit, tile ) then
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
        local path = Pathfinding.get_path_to_tile(all_tile_costs, destination)

        local action_ctx: MenuContext = {
            acting_unit = { unit = unit},
            destination = { point = destination, path = path},
            target_unit = { unit = choice.target }
        }
        LOG.info(unit.id .. " will attack "..choice.target.id)
        self.ctx.services.event_bus:emit("MOVE_AND_ATTACK", action_ctx)
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
            or not self.ctx.battle_map:tile_is_legal_destination(unit, point) do
            point = all_tile_costs:get_point(point).prev
        end

        local path = Pathfinding.get_path_to_tile(all_tile_costs, point)

        local action_ctx = {
            acting_unit = { unit = unit },
            destination = { point = point, path = path }
        }
        LOG.info(unit.id .. " will move to "..point.x..","..point.y)
        self.ctx.services.event_bus:emit("MOVE_AND_WAIT", action_ctx)
    else
        LOG.warn("WARN: No valid moves for "..unit.id.. "!")
    end
end

function EnemyAIEngine:handle_enemy_turn()
    self.ctx.services.task_manager:start_routine(function()
        local enemies = self.ctx.battle_map:get_units(unit_is_enemy)

        for _,enemy in ipairs(enemies) do
            self:compute_enemy_ai(enemy)
            while self.ctx.tactics_engine:is_blocked() do
                yield()
            end
        end

        self.ctx.services.event_bus:emit("TACTICS_END_ENEMY_TURN")
    end)
end

function EnemyAIEngine.new(ctx: BattleContext): EnemyAIEngine
    local self: EnemyAIEngine = setmetatable({
        ctx = ctx
    }, { __index = EnemyAIEngine })
    self.ctx.services.event_bus:on("TACTICS_BEGIN_ENEMY_TURN", function() self:handle_enemy_turn() end)
    return self
end

return EnemyAIEngine
