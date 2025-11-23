include "src/util.lua"
include "src/tiles.lua"
include "src/combat.lua"
include "src/draw.lua"
local BattleUnit = include "src/tactics//battle_unit.lua"

local COLOR_MENU_PRIMARY = 32
local COLOR_MENU_SECONDARY = 7
local COLOR_MENU_TEXT = 7
local COLOR_MENU_HIGHLIGHT = 6
local COLOR_MENU_HIGHLIGHT_TEXT = 32

local MAP_OFFSET_X = 154
local MAP_OFFSET_Y = 11
local MAP_WIDTH = CONFIG.MAP_WIDTH
local MAP_HEIGHT = CONFIG.MAP_HEIGHT
local TILE_WIDTH = CONFIG.TILE_WIDTH
local TILE_HEIGHT = CONFIG.TILE_HEIGHT
local WALL_HEIGHT = CONFIG.WALL_HEIGHT
local UNIT_OFFSET_X = 1
local UNIT_OFFSET_Y = -3
local CURSOR_SPRITE = 8

local TEXT_HEIGHT = 7

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

-- set to true during actions
local battle_is_blocked = false

Battle = {}

function Battle:create(map_info)
    self.units = {}
    self.index_counter = 1
    -- map of [x][y] for each entity in the map
    self.tile_contents = {}
    for i=0,map_info.width do
        self.tile_contents[i] = {}
    end

    MENU_MANAGER.set_menu("MENU_PLAYER_TURN")

    for i = 0,3 do
        self:spawn_unit(CHARACTER_MANAGER.generate_character(), 2 + i%2, 2+i*2, SIDE_PLAYER)
    end
    for i = 0,3 do
        self:spawn_unit(CHARACTER_MANAGER.generate_character(), 7 + i%2, 3+i*2, SIDE_ENEMY)
    end
end

function Battle:get_unit_by_id(id)
    return self.units[id]
end

function Battle:get_unit_at_coordinates(x, y)
    local unit_id = self.tile_contents[x][y]
    if unit_id == nil then return nil end
    return self:get_unit_by_id(unit_id)
end

function Battle:get_targets_in_range(unit_id, x, y)
    local targets = {}
    local attacker = self.units[unit_id]
    local min_range = attacker.weapon.min_range
    local max_range = attacker.weapon.max_range
    for target in all(self.units) do
        if target.id ~= attacker.id then
            if target.side ~= attacker.side
                    and tile_has_distance_from_unit(
                    x, y,
                    target.x, target.y,
                    min_range, max_range
            ) then
                add(targets, target)
            end
        end
    end
    return targets
end

function Battle:get_units(filter)
    filter = filter or fn_true
    local units = {}
    for unit in all(self.units) do
        if filter(unit) then
            add(units, unit)
        end
    end
    return units
end

function Battle:refresh_units(filter)
    local units_to_refresh = self:get_units(filter)

    for unit in all(units_to_refresh) do
        unit.has_acted = false
    end
end

function Battle:is_blocked()
    return battle_is_blocked
end

function Battle:check_for_end()
    if self:is_blocked() then
        return { finished = false }
    end

    local players = self:get_units(unit_is_player)
    local enemies = self:get_units(unit_is_enemy)

    if (#players == 0) then
        return { finished = true, command = "BATTLE_END_VICTORY" }
    elseif (#enemies == 0) then
        return { finished = true, command = "BATTLE_END_FAILURE" }
    else
        return { finished = false }
    end
end

-- step data helpers

function get_unit_from_step(ctx, step)
    return Battle:get_unit_by_id(ctx[step].unit_id)
end

-- unit filters

function unit_is_player(unit)
    return unit.side == SIDE_PLAYER
end

function unit_is_enemy(unit)
    return unit.side == SIDE_ENEMY
end

-- grid filters

function tile_has_distance_from_unit(x1, y1, x2, y2, min_distance, max_distance)
    max_distance = max_distance or min_distance
    local distance = abs(x1-x2)+abs(y1-y2)
    printh("distance: "..distance)
    return distance >= min_distance and distance <= max_distance
end

-- validators

function validate_tile_is_in_unit_attack_range(selection, ctx)
    local unit = get_unit_from_step(ctx, "acting_unit")
    local min_distance = unit.weapon.min_range
    local max_distance = unit.weapon.max_range
    local destination = ctx["destination"]
    local unit_x = destination.x
    local unit_y = destination.y
    local target_x = selection.x
    local target_y = selection.y

    local target_unit = Battle:get_unit_at_coordinates(target_x, target_y)
    if target_unit == nil then return false end

    if target_unit.side == unit.side then return false end

    return tile_has_distance_from_unit(target_x, target_y, unit_x, unit_y, min_distance, max_distance)
end

function any_target_in_range(ctx)
    local unit = get_unit_from_step(ctx, "acting_unit")
    local destination = ctx["destination"]
    local unit_x = destination.x
    local unit_y = destination.y

    local units_in_range = Battle:get_targets_in_range(unit.id, unit_x, unit_y)
    return #units_in_range > 0
end

-- legal tile getters

function tiles_with_distance_from_unit_attacks(ctx)
    local unit = get_unit_from_step(ctx, "acting_unit")
    local min_distance = unit.weapon.min_range
    local max_distance = unit.weapon.max_range

    return tiles_with_distance_from_unit
    (min_distance, max_distance)
    (ctx)

end

function tiles_with_distance_from_tile(tile_x, tile_y, min_distance, max_distance)
    max_distance = max_distance or min_distance

    local reachable = {}
    for x=-max_distance,max_distance do
        local map_x = x + tile_x
        if map_x >= 0 and map_x < MAP_WIDTH then
            local abs_x = abs(x)
            local min_y_abs = max(0, min_distance-abs_x)
            local max_y_abs = max_distance-abs_x

            if max_y_abs >= min_y_abs then
                reachable[map_x] = {}
                for y=-max_y_abs,-min_y_abs do
                    local map_y = y + tile_y
                    if map_y >= 0 and map_y < MAP_HEIGHT then
                        reachable[map_x][map_y] = true
                    end
                end
                for y=min_y_abs,max_y_abs do
                    local map_y = y + tile_y
                    if map_y >= 0 and map_y < MAP_HEIGHT then
                        reachable[map_x][map_y] = true
                    end
                end
            end
        end
    end

    return reachable

end

function tiles_with_distance_from_unit(min_distance, max_distance)
    return function(ctx)
        local destination = ctx["destination"]
        local dest_x = destination.x
        local dest_y = destination.y
        return tiles_with_distance_from_tile(dest_x, dest_y, min_distance, max_distance)
    end
end

function tiles_in_movement_range(ctx)
    local unit = Battle:get_unit_by_id(ctx["acting_unit"].unit_id)

    return find_reachable_tiles(unit.x, unit.y, unit.side, 6)
end

function grid_selection_is_empty_or_acting_unit(grid_selection, ctx)
    local destination_unit = Battle:get_unit_at_coordinates(grid_selection.x, grid_selection.y)
    if destination_unit == nil then
        return true
    end
    local acting_unit = Battle:get_unit_by_id(ctx["acting_unit"].unit_id)
    return destination_unit.id == acting_unit.id
end

function selected_empty_tile_mapper (active_cursor)
    local selected_unit = Battle:get_unit_at_coordinates(active_cursor.x, active_cursor.y)
    if selected_unit == nil then
        return true, {x = active_cursor.x, y = active_cursor.y}
    end
    return false, nil
end

-- handlers

function Battle:handle_move_unit(ctx)
    local unit = get_unit_from_step(ctx, "acting_unit")
    local x = ctx["destination"].x
    local y = ctx["destination"].y

    battle_is_blocked = true
    start_routine(function()
        unit:start_walk_animation((x-unit.x) * TILE_WIDTH, (y-unit.y) * TILE_HEIGHT)
        while unit.animation_blocking do
            yield()
        end
        unit:end_animation()

        self:move_unit(unit, x, y)
        unit.has_acted = true

        MENU_MANAGER.set_menu("MENU_PLAYER_TURN")
        battle_is_blocked = false
    end)
end

BUS.on("MOVE_AND_WAIT", function(ctx) Battle:handle_move_unit(ctx) end)

function Battle:handle_move_and_attack(ctx)
    local unit = get_unit_from_step(ctx, "acting_unit")
    local x = ctx["destination"].x
    local y = ctx["destination"].y
    local target = get_unit_from_step(ctx, "target")

    battle_is_blocked = true
    start_routine(function()
        unit:start_walk_animation((x-unit.x) * TILE_WIDTH, (y-unit.y) * TILE_HEIGHT)
        while unit.animation_blocking do
            yield()
        end
        unit:end_animation()

        self:move_unit(unit, x, y)
        do_combat(unit, target)
        unit.has_acted = true

        MENU_MANAGER.set_menu("MENU_PLAYER_TURN")
        battle_is_blocked = false
    end)
end

BUS.on("MOVE_AND_ATTACK", function(ctx) Battle:handle_move_and_attack(ctx) end)

function grid_selection_is_available_player(grid_selection)
    local unit = Battle:get_unit_at_coordinates(grid_selection.x, grid_selection.y)

    if unit == nil then return false end
    if unit.side ~= SIDE_PLAYER then return false end
    if unit.has_acted then return false end

    return true
end

function Battle:spawn_unit(unit, x, y, side)
    if self.tile_contents[x][y] ~= nil then
        error("Tried to spawn unit in an occupied tile! (".. x .. "," .. y .. ")")
    end

    local battle_unit = BattleUnit.spawn(unit, x, y, side)

    local id = battle_unit.id
    self.units[id] = battle_unit
    self.tile_contents[x][y] = id
end

function Battle:update()
    local blocking_animation = false
    local all_players_acted = true

    for unit in all(self.units) do
        unit:update_animation()
        if unit.animation_blocking then
            blocking_animation = true
        end
        if unit.side == SIDE_PLAYER and not unit.has_acted then
            all_players_acted = false
        end
    end

    if blocking_animation then return end
    if all_players_acted then
        local status = Battle:check_for_end()

        if not status.finished then
            BUS.emit("TACTICS_END_PLAYER_TURN")
        end
    end
end

function Battle:tile_is_legal_destination(unit, x, y)
    local unit_id_at_destination = self.tile_contents[x][y]
    return (unit_id_at_destination == nil
            or unit_id_at_destination == unit.id)
end

function Battle:move_unit(unit, x, y)
    assert(self:tile_is_legal_destination(unit, x, y))

    self.tile_contents[unit.x][unit.y] = nil
    self.tile_contents[x][y] = unit.id
    unit.x = x
    unit.y = y
end

function Battle:kill_unit(unit)
    self.tile_contents[unit.x][unit.y] = nil
    self.units[unit.id] = nil
    unit:die()
end


function Battle:draw_tactics_debug()
    print(MENU_MANAGER.menu_state.menu_id, 3 + 3, 3 + 3, 6)
    print(MENU_MANAGER.menu_state.menu_step, 3 + 3, 11 + 3, 6)
    print("x: "..(MENU_MANAGER.menu_selection.x or "nil"), 3 + 3, 19 + 3, 6)
    print("y: "..(MENU_MANAGER.menu_selection.y or "nil"), 3 + 3, 27 + 3, 6)
    print("i: "..(MENU_MANAGER.menu_selection.i or "nil"), 3 + 3, 35 + 3, 6)

    print("ABCDEFGHIJKLMNOPQRSTUVWXYZABC", 4, 50, 6)
end

return Battle