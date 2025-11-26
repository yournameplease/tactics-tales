include "src/util.lua"
include "src/tiles.lua"
include "src/combat.lua"
include "src/draw.lua"
local BattleUnit = include "src/tactics/battle_unit.lua"

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

Battle = {}
Battle.__index = Battle

function Battle.new(battle_state)
    local self = setmetatable({}, Battle)
    self.battle_is_blocked = false
    self.battle_state = battle_state
    BUS.on("MOVE_AND_WAIT", function(ctx)
        self:handle_move_unit(ctx)
    end)
    BUS.on("MOVE_AND_ATTACK", function(ctx)
        self:handle_move_and_attack(ctx)
    end)
    return self
end

function Battle:refresh_units(filter)
    local units_to_refresh = self.battle_state:get_units(filter)

    for unit in all(units_to_refresh) do
        unit.has_acted = false
    end
end

function Battle:is_blocked()
    return self.battle_is_blocked
end



-- step data helpers

function Battle:get_unit_from_step(ctx, step)
    return self.battle_state:get_unit_by_id(ctx[step].unit_id)
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
    return distance >= min_distance and distance <= max_distance
end

-- validators

function Battle:validate_tile_is_in_unit_attack_range(selection, ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local min_distance = unit.weapon.min_range
    local max_distance = unit.weapon.max_range
    local destination = ctx["destination"]
    local unit_x = destination.x
    local unit_y = destination.y
    local target_x = selection.x
    local target_y = selection.y

    local target_unit = self.battle_state:get_unit_at_coordinates(target_x, target_y)
    if target_unit == nil then return false end

    if target_unit.side == unit.side then return false end

    return tile_has_distance_from_unit(target_x, target_y, unit_x, unit_y, min_distance, max_distance)
end

function Battle:any_target_in_range(ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local destination = ctx["destination"]
    local unit_x = destination.x
    local unit_y = destination.y

    local units_in_range = self.battle_state:get_targets_in_range(unit.id, unit_x, unit_y)
    return #units_in_range > 0
end

-- legal tile getters

-- @return  { [x][y] = { valid_selection, reachable, can_attack } }
function tiles_with_distance_from_unit_attacks(ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local min_distance = unit.weapon.min_range
    local max_distance = unit.weapon.max_range

    local destination = ctx["destination"]
    local dest_x = destination.x
    local dest_y = destination.y
    local tiles_in_distance =  find_tiles_with_distance_from_tile(dest_x, dest_y, min_distance, max_distance)

    local tiles = Array2D.new(MAP_WIDTH, MAP_HEIGHT)

    for x, r in pairs(tiles_in_distance) do
        for y, in_range in pairs(r) do
            if in_range then
                local tile = tiles:get(x,y)
                if tile == nil then tile = {} end
                tile.can_attack = true
                tile.valid_selection = true
                tiles:set(x, y, tile)
            end
        end
    end

    return tiles
end

-- @return  { [x][y] = bool }
function find_tiles_with_distance_from_tile(tile_x, tile_y, min_distance, max_distance)
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

-- @return  { [x][y] = { valid_selection, reachable, can_attack } }
function Battle:tiles_in_movement_and_attack_range(ctx)
    local unit = self.battle_state:get_unit_by_id(ctx["acting_unit"].unit_id)
    local min_range = unit.weapon.min_range
    local max_range = unit.weapon.max_range

    local reachable_tiles = find_reachable_tiles(unit.x, unit.y, unit.side, unit.movement, self.battle_state)

    local tiles = Array2D.new(MAP_WIDTH, MAP_HEIGHT)


    for x, r in pairs(reachable_tiles) do
        for y, reachable  in pairs(r) do
            if reachable then
                local tile = tiles:get(x,y)
                if tile == nil then tile = {} end
                tile.reachable = true
                tile.valid_selection = true
                tiles:set(x, y, tile)
                local tiles_in_attack_range = find_tiles_with_distance_from_tile(x, y, min_range, max_range)

                for ax, ar in pairs(tiles_in_attack_range) do
                    for ay, can_attack  in pairs(ar) do
                        if can_attack then
                            local a_tile = tiles:get(ax,ay)
                            if a_tile == nil then a_tile = {} end
                            a_tile.can_attack = true
                            tiles:set(ax, ay, a_tile)
                        end
                    end
                end
            end
        end
    end

    return tiles
end

function Battle:grid_selection_is_empty_or_acting_unit(grid_selection, ctx)
    local destination_unit = self.battle_state:get_unit_at_coordinates(grid_selection.x, grid_selection.y)
    if destination_unit == nil then
        return true
    end
    local acting_unit = Battle:get_unit_by_id(ctx["acting_unit"].unit_id)
    return destination_unit.id == acting_unit.id
end

function Battle:selected_empty_tile_mapper (active_cursor)
    local selected_unit = self.battle_state:get_unit_at_coordinates(active_cursor.x, active_cursor.y)
    if selected_unit == nil then
        return true, {x = active_cursor.x, y = active_cursor.y}
    end
    return false, nil
end

-- handlers

function Battle:handle_move_unit(ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local x = ctx["destination"].x
    local y = ctx["destination"].y
    local path = ctx["destination"].path

    self.battle_is_blocked = true
    start_routine(function()
        unit:start_walk_animation(path)
        while unit.animation_blocking do
            yield()
        end
        unit:end_animation()

        self.battle_state:move_unit(unit, x, y)
        unit.has_acted = true

        MENU_MANAGER.set_menu("MENU_PLAYER_TURN")
        self.battle_is_blocked = false
    end)
end

function Battle:handle_move_and_attack(ctx)
    local unit = self:get_unit_from_step(ctx, "acting_unit")
    local x = ctx["destination"].x
    local y = ctx["destination"].y
    local path = ctx["destination"].path
    local target = self:get_unit_from_step(ctx, "target")

    self.battle_is_blocked = true
    start_routine(function()
        unit:start_walk_animation(path)
        while unit.animation_blocking do
            yield()
        end
        unit:end_animation()

        self.battle_state:move_unit(unit, x, y)
        do_combat(unit, target, self.battle_state)
        unit.has_acted = true

        MENU_MANAGER.set_menu("MENU_PLAYER_TURN")
        self.battle_is_blocked = false
        LOG.debug("unblockiung battle")
    end)
end

function Battle:grid_selection_is_available_player(grid_selection)
    local unit = self.battle_state:get_unit_at_coordinates(grid_selection.x, grid_selection.y)

    if unit == nil then return false end
    if unit.side ~= SIDE_PLAYER then return false end
    if unit.has_acted then return false end

    return true
end


function Battle:update()
    local blocking_animation = false
    local all_players_acted = true

    for unit in all(self.battle_state:get_units()) do
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
        BUS.emit("TACTICS_END_PLAYER_TURN")
    end
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
