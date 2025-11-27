include "src/tiles.lua"

--[[
AI Mk 1:
- perform full dijkstra on tiles, with ancestor references
- if enemy in range, look at all tiles within attack range
- - pick one at random
- else
- - pick nearest  enemy, move as close as possible
]]

function compute_enemy_ai(unit, tactics_engine)
    local tile_manager = battle_manager.tile_manager -- TODO: global state
    local all_tile_costs = tile_manager:calculate_all_tile_costs(unit.x, unit.y, unit.side, 999, tactics_engine.battle_state)
LOG.debug(#all_tile_costs)
    local enemies = tactics_engine.battle_state:get_units(unit_is_player)

    local potential_attacks = {}
    local deep_moves = {}

    for e in all(enemies) do
        local tiles_in_range =
            battle_manager.tactics_engine:find_tiles_with_distance_from_tile(e.x, e.y, unit.weapon.min_range, unit.weapon.max_range)
        for x,row in pairs(tiles_in_range) do
            for y, reachable in pairs(row) do
                if reachable then
                    if all_tile_costs[x] ~= nil and all_tile_costs[x][y] ~= nil then
                        if all_tile_costs[x][y].cost <= unit.stats.movement then
                            if tactics_engine.battle_state:tile_is_legal_destination(unit, x, y) then
                                add(potential_attacks, {x = x, y = y, target = e})
                            end
                        else
                            add(deep_moves, {x = x, y = y})
                        end
                    end
                end
            end
        end
    end

    if #potential_attacks > 0 then
        local choice = potential_attacks[1]

        local x = choice.x
        local y = choice.y
        local path = tile_manager:get_path_to_tile(all_tile_costs, x, y)

        local action_ctx = {
            acting_unit = { unit_id = unit.id },
            destination = { x = choice.x, y = choice.y, path = path},
            target = { unit_id = choice.target.id }
        }
        LOG.info(unit.id .. " will attack "..choice.target.id)
        BUS.emit("MOVE_AND_ATTACK", action_ctx)
    elseif #deep_moves > 0 then
        local min_cost_deep_move = deep_moves[1]
        local min_cost = 999
        for deep_move in all(deep_moves) do
            if all_tile_costs[deep_move.x][deep_move.y].cost < min_cost then
                min_cost = all_tile_costs[deep_move.x][deep_move.y].cost
                min_cost_deep_move = deep_move
            end
        end
        -- follow until first tile in range
        local x = min_cost_deep_move.x
        local y = min_cost_deep_move.y
        while all_tile_costs[x][y].cost > unit.stats.movement do
            x = all_tile_costs[x][y].prev.x
            y = all_tile_costs[x][y].prev.y
        end

        local path = tile_manager:get_path_to_tile(all_tile_costs, x, y)

        local action_ctx = {
            acting_unit = { unit_id = unit.id },
            destination = { x = x, y = y, path = path }
        }
        LOG.info(unit.id .. " will move to "..x..","..y)
        BUS.emit("MOVE_AND_WAIT", action_ctx)
    else
        LOG.warn("WARN: No valid moves for "..unit.id.. "!")
    end
end

function handle_enemy_turn(tactics_engine)
    start_routine(function()
        local enemies = tactics_engine.battle_state:get_units(unit_is_enemy)

        for enemy in all(enemies) do
            compute_enemy_ai(enemy, tactics_engine)
            while tactics_engine:is_blocked() do
                yield()
            end
        end

        BUS.emit("TACTICS_END_ENEMY_TURN")
    end)
end

BUS.on("TACTICS_BEGIN_ENEMY_TURN", handle_enemy_turn)
