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

local COLOR_SCREEN_DECORATION_PRIMARY = 22
local COLOR_SCREEN_DECORATION_HIGHLIGHT = 6
local COLOR_SCREEN_DECORATION_SHADOW = 5
local COLOR_SCREEN_DECORATION_INTERIOR = 21

local SCREEN_WIDTH = CONFIG.SCREEN_WIDTH
local SCREEN_HEIGHT = CONFIG.SCREEN_HEIGHT
local SCREEN_DECORATION_PADDING = 3

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

    set_menu("MENU_PLAYER_TURN")

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

        set_menu("MENU_PLAYER_TURN")
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

        set_menu("MENU_PLAYER_TURN")
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

-- kind
-- selected_data_mapper -- returns (success bool, data) to store
-- select_transition
local MENU_DATA = {
    ["MENU_PLAYER_TURN"] = {
        initial_step = "SELECT_UNIT",
        steps = {
            ["SELECT_UNIT"] = {
                kind = "CURSOR_GRID",
                store_key = "acting_unit",
                validator = grid_selection_is_available_player,
                next_state = "SELECT_DESTINATION"
            },
            ["SELECT_DESTINATION"] = {
                kind = "CURSOR_GRID",
                store_key = "destination",
                validator = grid_selection_is_empty_or_acting_unit,
                next_state = "SELECT_ACTION",
                get_legal_tiles = tiles_in_movement_range
            },
            ["SELECT_ACTION"] = {
                kind = "CURSOR_VERTICAL_LIST",
                options_generator = function(ctx)
                    local options = {}
                    -- if target in range
                    if any_target_in_range(ctx) then
                        add(options, {
                            text = "Attack",
                            next_state = "SELECT_TARGET"
                        })
                    end

                    add(options, {
                        text = "Wait",
                        finish_command = { kind = "MOVE_AND_WAIT" }
                    })

                    return options
                end
            },
            ["SELECT_TARGET"] = {
                kind = "CURSOR_GRID",
                store_key = "target",
                validator = validate_tile_is_in_unit_attack_range,
                finish_command = { kind = "MOVE_AND_ATTACK" },
                get_legal_tiles = tiles_with_distance_from_unit_attacks
            },
        }
    }
}

local menu_state = {}
local menu_ctx = {}
local menu_selection = {}
local selection_history = {}

function handle_menu_select()
    local menu_data = MENU_DATA[menu_state.menu_id]
    local step_data = menu_data.steps[menu_state.menu_step]

    if step_data.validator ~= nil then
        local validation = step_data.validator(menu_selection, menu_ctx)
        if not validation then return end
    end

    if menu_state.options ~= nil then
        step_data = menu_state.options[menu_selection.i]
    end

    add(selection_history, {
        step = menu_state.menu_step,
        selection = menu_selection
    })

    if step_data.kind == "CURSOR_GRID" then
        printh("unit getting")
        local selected_unit = Battle:get_unit_at_coordinates(menu_selection.x, menu_selection.y)
        if selected_unit ~= nil then
            menu_selection.unit_id = selected_unit.id
        end
    end

    if step_data.store_key ~= nil then
        printh("writing to "..step_data.store_key.."...")
        printh("x="..(menu_selection.x or "nil"))
        printh("y="..(menu_selection.y or "nil"))
        printh("i="..(menu_selection.i or "nil"))
        printh("unit_id="..(menu_selection.unit_id or "nil"))
        menu_ctx[step_data.store_key] = deepcopy(menu_selection)
    end

    if step_data.next_state ~= nil then
        populate_menu_state(step_data.next_state, menu_ctx)
    end

    if step_data.finish_command ~= nil then
        printh("emitting "..step_data.finish_command.kind)
        BUS.emit(step_data.finish_command.kind, menu_ctx)
    end
end

function populate_menu_state(new_step, ctx)
    menu_state.menu_step = new_step

    local menu_data = MENU_DATA[menu_state.menu_id]
    local new_step_data = menu_data.steps[menu_state.menu_step]
    menu_state.kind = new_step_data.kind
    if new_step_data.options_generator ~= nil then
        menu_state.options = new_step_data.options_generator(ctx)
        printh ("generated "..#menu_state.options.." options")
    else
        menu_state.options = nil
    end
    if new_step_data.get_legal_tiles ~= nil then
        menu_state.legal_tiles = new_step_data.get_legal_tiles(ctx)
    else
        menu_state.legal_tiles = nil
    end
end

function handle_menu_back()
    if #selection_history == 0 then return end

    local previous_step = selection_history[#selection_history]
    -- TODO: use this to get last cursor position
    -- or, just push the entire active cursor onto a list
    selection_history[#selection_history] = nil
    populate_menu_state(previous_step.step, menu_ctx)
    selection = previous_step.selection
end

local update_cursor = {
    ["CURSOR_GRID"] = function (joy)
        menu_selection.x = mid(0, menu_selection.x + joy.dxp, menu_state.x_max - 1)
        menu_selection.y = mid(0, menu_selection.y + joy.dyp, menu_state.y_max - 1)
    end,
    ["CURSOR_VERTICAL_LIST"] = function (joy)
        menu_selection.i = mid(1, menu_selection.i + joy.dyp, #menu_state.options)
    end,
    ["CURSOR_HORIZONTAL_LIST"] = function (joy)
        menu_selection.i = mid(1, menu_selection.i + joy.dxp, #menu_state.options)
    end,
}


function set_menu(menu_id)
    -- TODO: make functional?
    menu_state = {
        kind = "CURSOR_GRID",
        handle_back = nil,
        x_max = 20, -- TODO
        y_max = 15, -- TODO
        menu_id = menu_id,
        menu_step = MENU_DATA[menu_id].initial_step
    }
    menu_selection = {
        x = 0,
        y = 0,
        i = 0
    }
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

function Battle:update(joy)
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

    if joy.lp then
        BUS.emit("TACTICS_END_PLAYER_TURN")
    elseif joy.bp then
        handle_menu_back()
    elseif joy.ap then
        handle_menu_select()
    else
        update_cursor[menu_state.kind](joy)
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

function draw_menu_overlay()
    local menu_boxes = {
        {
            x = SCREEN_DECORATION_PADDING, y = SCREEN_DECORATION_PADDING,
            w = SCREEN_WIDTH - MAP_WIDTH * TILE_WIDTH - 4 * SCREEN_DECORATION_PADDING,
            h = SCREEN_HEIGHT - 2 * SCREEN_DECORATION_PADDING
        },
        {
            x = MAP_OFFSET_X, y = MAP_OFFSET_Y,
            w = MAP_WIDTH * TILE_WIDTH,
            h = MAP_HEIGHT * TILE_HEIGHT
        },
    }

    cls(COLOR_SCREEN_DECORATION_PRIMARY)
    for box in all(menu_boxes) do
        rectfill(box.x-1, box.y, box.x+box.w-1, box.y+box.h, COLOR_SCREEN_DECORATION_HIGHLIGHT)
        rectfill(box.x, box.y-1, box.x+box.w, box.y+box.h-1, COLOR_SCREEN_DECORATION_SHADOW)
        rectfill(box.x, box.y, box.x+box.w-1, box.y+box.h-1, COLOR_SCREEN_DECORATION_INTERIOR)
    end
end

function Battle:draw()
    draw_menu_overlay()

    camera(-MAP_OFFSET_X, -MAP_OFFSET_Y)

    -- draw row-by row, top to bottom aka back to front

        --map(0, 0, 0, 0, MAP_WIDTH, MAP_HEIGHT, nil, TILE_WIDTH, TILE_HEIGHT)
    -- TODO: preload layers
    local layers = fetch("map/0.map")
    local layer_ground = layers[2].bmp
    local layer_wall = layers[1].bmp
    local wall_offset = WALL_HEIGHT - TILE_HEIGHT
    for y = 0, MAP_HEIGHT-1 do
        map(layer_ground, 0, y, 0, y * TILE_HEIGHT, MAP_WIDTH, 1, nil, TILE_WIDTH, TILE_HEIGHT)


        -- highlight legal tiles
        if menu_state.legal_tiles ~= nil then
            fillp(
            -- 1:2 diagonal slashes
            --0b00111111,
            --0b11111100,
            --0b11110011,
            --0b11001111,
            --0b00111111,
            --0b11111100,
            --0b11110011,
            --0b11001111
            -- 1:2 checkerboard
                0x33,
                0xCC,
                0x33,
                0xCC,
                0x33,
                0xCC,
                0x33,
                0xCC
            )
            poke(0x550b,0x3f)
            palt()
            color(28)
            for x = 0, MAP_WIDTH-1 do
                if menu_state.legal_tiles[x] ~= nil and menu_state.legal_tiles[x][y] then
                    rrectfill(x*TILE_WIDTH, y*TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)
                end
            end
            poke(0x550b,0x00)
            fillp()
            color()
        end

        for x = 0, MAP_WIDTH-1 do
            if self.tile_contents[x][y] ~= nil then
                draw_unit(self:get_unit_at_coordinates(x, y))
            end
        end
        map(layer_wall, 0, y, 0, y * TILE_HEIGHT - wall_offset, MAP_WIDTH, 1, nil, TILE_WIDTH, WALL_HEIGHT)
    end

    if menu_selection.x ~= nil and menu_selection.y ~= nil then
        local x = menu_selection.x * TILE_WIDTH
        local y = menu_selection.y * TILE_HEIGHT
        spr(CURSOR_SPRITE, x, y)

        if menu_state.kind == "CURSOR_VERTICAL_LIST" then
            local selected_i = menu_selection.i
            local options = menu_state.options
            local PADDING = 2

            local menu_x = x + TILE_WIDTH
            local menu_y = y + TILE_HEIGHT
            local menu_w = 2*PADDING + 30
            local menu_h = 2*PADDING + #options * (TEXT_HEIGHT+1) -1
            rrectfill(menu_x, menu_y, menu_w, menu_h, 1, COLOR_MENU_PRIMARY)
            for i,opt in ipairs(options) do
                if i == selected_i then
                    rrectfill(menu_x, menu_y+PADDING-1+(TEXT_HEIGHT+1)*(i-1), menu_w, TEXT_HEIGHT+2, 0, COLOR_MENU_HIGHLIGHT)
                    print(opt.text, menu_x+PADDING, menu_y+PADDING+(TEXT_HEIGHT+1)*(i-1), COLOR_MENU_HIGHLIGHT_TEXT)
                else
                    print(opt.text, menu_x+PADDING, menu_y+PADDING+(TEXT_HEIGHT+1)*(i-1), COLOR_MENU_TEXT)
                end
            end
            rrect(menu_x, menu_y, menu_w, menu_h, 1, COLOR_MENU_SECONDARY)
        end
    end

    camera()

    self:draw_tactics_debug()
end

function draw_unit(unit)
    local side = unit.side
    local x = unit.x
    local y = unit.y
    local has_acted = unit.has_acted

    local tile_x = x * TILE_WIDTH
    local tile_y = y * TILE_HEIGHT

    local shadow_color
    if has_acted then
        shadow_color = 0
    else
        shadow_color = 7
    end
    draw_shadow(shadow_color,
            function(draw_x,draw_y) unit:draw(draw_x, draw_y, side, false) end,
            tile_x + UNIT_OFFSET_X, tile_y + UNIT_OFFSET_Y)

    unit:draw(tile_x + UNIT_OFFSET_X, tile_y + UNIT_OFFSET_Y, side, true)

    local hp_current = unit.hp_current
    local hp_max = unit.stats.hp_max
    draw_health_bar(hp_current, hp_max, tile_x+1, tile_y+UNIT_OFFSET_Y-5, TILE_WIDTH-2, 4)
end

function draw_health_bar(hp_current, hp_max, x, y, width, height)
    rrectfill(x, y, width, height, 1, COLOR_MENU_PRIMARY)
    local bar_width = flr(hp_current*(width-2) / hp_max)
    rrectfill(x+1, y+1, bar_width, height-2, 1, 27)
    rrect(x, y, width, height, 1, COLOR_MENU_SECONDARY)
end

function Battle:draw_tactics_debug()
    --print(menu_state.menu_id, 3 + 3, 3-1 + 3, 7)
    --print(menu_state.menu_id, 3 + 3+1, 3 + 3, 5)
    print(menu_state.menu_id, 3 + 3, 3 + 3, 6)
    --print(menu_state.menu_step, 3 + 3, 11-1 + 3, 7)
    --print(menu_state.menu_step, 3 + 3+1, 11 + 3, 5)
    print(menu_state.menu_step, 3 + 3, 11 + 3, 6)
    --print("x: "..(menu_selection.x or "nil"), 3 + 3, 19-1 + 3, 7)
    --print("x: "..(menu_selection.x or "nil"), 3 + 3+1, 19 + 3, 5)
    print("x: "..(menu_selection.x or "nil"), 3 + 3, 19 + 3, 6)
    --print("y: "..(menu_selection.y or "nil"), 3 + 3, 27-1 + 3, 7)
    --print("y: "..(menu_selection.y or "nil"), 3 + 3+1, 27 + 3, 5)
    print("y: "..(menu_selection.y or "nil"), 3 + 3, 27 + 3, 6)
    --print("i: "..(menu_selection.i or "nil"), 3 + 3, 35-1 + 3, 7)
    --print("i: "..(menu_selection.i or "nil"), 3 + 3+1, 35 + 3, 5)
    print("i: "..(menu_selection.i or "nil"), 3 + 3, 35 + 3, 6)

    print("ABCDEFGHIJKLMNOPQRSTUVWXYZABC", 4, 50, 6)
end

return Battle