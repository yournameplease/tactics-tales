require("profiler")
require("src/tactics/debug")
require("src/tactics/config")

require("src/tactics/ui/box")
local DrawTargetManager = require("src/tactics/draw/draw_target_manager").DrawTargetManager
require("src/tactics/battle/battle_menu_manager")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/battle/battle_map")
require("src/tactics/util/array_2d")
local menu_cursor = require("src/tactics/menu/menu_cursor")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local grid_cursor = require("src/tactics/menu/cursor/grid_cursor")
local BattleMenuContext = require("src/tactics/battle/battle_context").BattleMenuContext
local BattleUIContext = require("src/tactics/battle/battle_ui_context").BattleUIContext
local maps = require("src/tactics/util/maps")
require("src/tactics/types")

local CharacterRenderer = require("src/tactics/character/character_renderer")

global record TacticsMap
    is UIElement
    map_width: integer
    map_height: integer
end

setmetatable(TacticsMap, { __index = Box})


local COLOR_MENU_PRIMARY = CONFIG.COLOR_MENU_PRIMARY
local COLOR_MENU_SECONDARY = CONFIG.COLOR_MENU_SECONDARY
local COLOR_MENU_TEXT = CONFIG.COLOR_MENU_TEXT
local COLOR_MENU_HIGHLIGHT = CONFIG.COLOR_MENU_HIGHLIGHT
local COLOR_MENU_HIGHLIGHT_TEXT = CONFIG.COLOR_MENU_HIGHLIGHT_TEXT

local MAP_WIDTH = CONFIG.MAP_WIDTH
local MAP_HEIGHT = CONFIG.MAP_HEIGHT
local TILE_SIZE = CONFIG.TILE_SIZE
local HALF_HEIGHT = TILE_SIZE.y >> 1
local BASE_TILE_SPRITE = 2 * 256

-- UNIT offset should instead be the feet position, and draw using skeleton position
local UNIT_OFFSET_Y = -3
local CURSOR_SPRITE = 8

local TEXT_HEIGHT = 7

local FOOT_GROUND_ANCHOR = Point.of(8,12)

function TacticsMap.new(map_width: integer, map_height: integer, props: UIElement): TacticsMap
    local box = Box.new(props) as TacticsMap
    setmetatable(box, { __index = TacticsMap})

    box.map_width = map_width or MAP_WIDTH
    box.map_height = map_height or MAP_HEIGHT

    box.w = box.map_width * TILE_SIZE.x + box.internal_margin.l + box.internal_margin.r
    box.h = box.map_height * TILE_SIZE.y + box.internal_margin.t + box.internal_margin.b

    return box
end

local record AnimatedUnitPosition
    id: integer
    point: Point
end

local function compute_animated_unit_positions(battle_map: BattleMap): { AnimatedUnitPosition }
    return maps.map(
            battle_map:get_all_units(),
            function(unit: BattleUnit): AnimatedUnitPosition
                local animation_offset = CharacterRenderer.get_animation_offset(unit)
                return {
                    id = unit.id,
                    point = unit.tile * TILE_SIZE + animation_offset,
                }
            end
    )
end

local function draw_floating_menu(x: integer, y: integer, cursor: list_cursor.ListMenuCursor<BattleMenuContext>)
    local selected_i = cursor.i
    local options = cursor.options
    local PADDING = 2

    local max_text_width = 0
    for _,opt in ipairs(options) do
        local text_width = pt.print(opt.text, 0, -1000) as integer
        max_text_width = pt.max(max_text_width, text_width)
    end

    local menu_x = x + TILE_SIZE.x
    local menu_y = y + TILE_SIZE.y
    local menu_w = 2*PADDING + max_text_width
    local menu_h = 2*PADDING + #options * (TEXT_HEIGHT+1) -1
    pt.rrectfill(menu_x, menu_y, menu_w, menu_h, 1, COLOR_MENU_PRIMARY)
    for i,opt in ipairs(options) do
        if i == selected_i then
            pt.rrectfill(menu_x, menu_y+PADDING-1+(TEXT_HEIGHT+1)*(i-1), menu_w, TEXT_HEIGHT+2, 0, COLOR_MENU_HIGHLIGHT)
            pt.print(opt.text, menu_x+PADDING, menu_y+PADDING+(TEXT_HEIGHT+1)*(i-1), COLOR_MENU_HIGHLIGHT_TEXT)
        else
            pt.print(opt.text, menu_x+PADDING, menu_y+PADDING+(TEXT_HEIGHT+1)*(i-1), COLOR_MENU_TEXT)
        end
    end
    pt.rrect(menu_x, menu_y, menu_w, menu_h, 1, COLOR_MENU_SECONDARY)
end

local function should_draw_shadow(unit: BattleUnit, ctx: BattleUIContext): boolean
    if ctx.acting_unit ~= nil and unit.id == ctx.acting_unit.id then
        return true
    end
    if ctx.hovered_unit ~= nil and unit.id == ctx.hovered_unit.id then
        return true
    end

    return false
end

local function draw_unit(unit: BattleUnit, draw_target_manager: DrawTargetManager, ctx: BattleUIContext)
    local unit_tile = unit.tile
    local draw_shadow = should_draw_shadow(unit, ctx)

    local world_point = unit_tile * TILE_SIZE

    CharacterRenderer.draw_health_bar(unit, world_point + FOOT_GROUND_ANCHOR, true, true)
    CharacterRenderer.draw(unit, world_point + FOOT_GROUND_ANCHOR, draw_target_manager, true, true, draw_shadow)
end

local function set_ud_tile(ud: Userdata, t: Point, s: integer)
    -- LOG.trace(t, s)
    ud:set(t.x, t.y, BASE_TILE_SPRITE + s)
end

local function get_path_layer(state: UIContextManager): Userdata
    local menu = state.battle_context.battle_menu_manager
    local cursor: menu_cursor.MenuCursor<BattleMenuContext> = menu.menu_cursor

    local path_layer = pt.userdata("i16", state.battle_context.battle_map.width, state.battle_context.battle_map.height)
    if cursor is grid_cursor.GridMenuCursor<BattleMenuContext> then
        local path = cursor.path
        if path ~= nil then
            local len = #path
            if len > 1 then
                do
                    local step_offset = path[2] - path[1]
                    local s = 0
                    if step_offset.x == 0 then
                        if step_offset.y == 1 then
                            s = 205
                        elseif step_offset.y == -1 then
                            s = 203
                        end
                    elseif step_offset.y == 0 then
                        if step_offset.x == 1 then
                            s = 204
                        elseif step_offset.x == -1 then
                            s = 202
                        end
                    end
                    assert(s ~= 0)
                    set_ud_tile(path_layer, path[1], s)
                end
                for i = 2, #path-1 do
                    local step_offset = path[i+1] - path[i-1]
                    local one_step_offset = path[i] - path[i-1]
                    local s = 0
                    if step_offset.x == 0 then
                        s = 193
                    elseif step_offset.y == 0 then
                        s = 192
                    else
                        local dir = step_offset.x * step_offset.y -- +/- 1
                        if dir == 1 then -- 45 deg down
                            if one_step_offset.x == 1 or one_step_offset.y == -1 then
                                s = 196
                            else
                                s = 195
                            end
                        else -- 45 deg up
                            if one_step_offset.x == 1 or one_step_offset.y == 1 then
                                s = 194
                            else
                                s = 197
                            end
                        end
                    end
                    assert(s ~= 0)
                    set_ud_tile(path_layer, path[i], s)
                end
                do
                    local step_offset = path[#path] - path[#path-1]
                    local s = 0
                    if step_offset.x == 0 then
                        if step_offset.y == -1 then
                            s = 201
                        elseif step_offset.y == 1 then
                            s = 199
                        end
                    elseif step_offset.y == 0 then
                        if step_offset.x == -1 then
                            s = 200
                        elseif step_offset.x == 1 then
                            s = 198
                        end
                    end
                    assert(s ~= 0)
                    set_ud_tile(path_layer, path[#path], s)
                end
            end
        end
        return path_layer
    end
end

function TacticsMap:draw(state: UIContextManager, draw_target_manager: DrawTargetManager, ui_theme: UITheme)
    profile("tactics_map_draw")
    profile("draw_map_pre_rows")
    Box._draw(self, state, draw_target_manager, ui_theme)

    local battle_map = state.battle_context.battle_map
    local menu = state.battle_context.battle_menu_manager

    local ud_width = self.w
    -- to top of screen
    local ud_height = self.h + self.x + self.internal_margin.t
    local draw_x = self.x + self.internal_margin.l
    local draw_y = self.y + self.internal_margin.t
    draw_target_manager:push_target(ud_width, ud_height, 0, draw_y)

    -- draw row-by row, top to bottom aka back to front

    -- pre-compute actor animations for z-ordering
    local unit_positions = compute_animated_unit_positions(state.battle_context.battle_map)

    profile("sort_units_z")
    local sorted_units = pt.userdata("i16", 2, #unit_positions) as Userdata
    for i,u in ipairs(unit_positions) do
        sorted_units:set(0,i-1, u.point.y)
        sorted_units:set(1,i-1, u.id)
    end
    sorted_units:sort()
    profile("sort_units_z")

    local drawn_unit_count = 0
    -- TODO: preload layers
    local layers = state.battle_context.battle_map.layers
    local layer_ground = layers.terrain.ground
    local layer_wall_back = layers.terrain.back_wall
    local layer_wall_mid = layers.terrain.mid_wall
    local layer_wall_front = layers.terrain.front_wall
    profile("compute_path_layer")
    local layer_path = get_path_layer(state)
    profile("compute_path_layer")

    local cursor_tile: Point = nil
    local cursor = menu.menu_cursor
    if cursor is grid_cursor.GridMenuCursor<BattleMenuContext> then
        cursor_tile = cursor.point
    elseif menu.menu_state.point ~= nil then
        cursor_tile = menu.menu_state.point
    end


    -- draw ground
    profile("draw_ground")
    pt.map(layer_ground, 0, 0, 0, 0, self.map_height, self.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)
    -- highlight legal tiles
    if cursor is grid_cursor.GridMenuCursor<BattleMenuContext> then
        if cursor.legal_tiles ~= nil then
            pt.fillp(
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
            pt.poke(0x550b,0x3f)
            pt.set_palt(0, true)
            for x = 0, self.map_width-1 do
                for y = 0, self.map_height-1 do
                    local highlighted_tile = cursor.legal_tiles:get(x, y)
                    if highlighted_tile ~= nil and (highlighted_tile.reachable or highlighted_tile.can_attack)  then
                        if (highlighted_tile.reachable) then
                            pt.set_color(28)
                        elseif highlighted_tile.can_attack then
                            pt.set_color(8)
                        else
                            error("invalid state")
                        end
                        pt.rrectfill(x*TILE_SIZE.x+1, y*TILE_SIZE.y+1, TILE_SIZE.x-2, TILE_SIZE.y-2)
                    end
                end
            end
            pt.poke(0x550b,0x00)
            pt.fillp()
            pt.reset_color()
        end
    end
    profile("draw_ground")
    profile("draw_map_pre_rows")
    
    profile("draw_map_rows")
    for y = 0, self.map_height-1 do
        pt.map(layer_wall_back, 0, y, 0, (y-1) * TILE_SIZE.y, self.map_width, 1, nil, TILE_SIZE.x, TILE_SIZE.y)

        pt.map(layer_path, 0, y, 0, y * TILE_SIZE.y, self.map_width, 1, nil, TILE_SIZE.x, TILE_SIZE.y)

        while drawn_unit_count < #unit_positions and sorted_units:get(0, drawn_unit_count) <= (y) * TILE_SIZE.y + HALF_HEIGHT do
            local unit_id = sorted_units:get(1, drawn_unit_count)
            local unit = battle_map:get_unit_by_id(unit_id)
            draw_unit(unit, draw_target_manager, state.battle_context)
            drawn_unit_count = drawn_unit_count + 1
        end

        pt.map(layer_wall_mid, 0, y, 0, y * TILE_SIZE.y - HALF_HEIGHT, self.map_width, 1, nil, TILE_SIZE.x, TILE_SIZE.y)

        while drawn_unit_count < #unit_positions and sorted_units:get(0, drawn_unit_count) <= (y+1) * TILE_SIZE.y do
            local unit_id = sorted_units:get(1, drawn_unit_count)
            local unit = battle_map:get_unit_by_id(unit_id)
            draw_unit(unit, draw_target_manager, state.battle_context)
            drawn_unit_count = drawn_unit_count + 1
        end

        -- TODO: this is better with transparency
        if cursor_tile ~= nil then
            local c_x = cursor_tile.x * TILE_SIZE.x
            local c_y = cursor_tile.y * TILE_SIZE.y
            pt.spr(CURSOR_SPRITE, c_x, c_y)
        end

        pt.map(layer_wall_front, 0, y, 0, y * TILE_SIZE.y, self.map_width, 1, nil, TILE_SIZE.x, TILE_SIZE.y)
    end
    profile("draw_map_rows")

    profile("draw_map_post_rows")
    if cursor_tile ~= nil then
        local x = cursor_tile.x * TILE_SIZE.x
        local y = cursor_tile.y * TILE_SIZE.y
        -- pt.spr(CURSOR_SPRITE, x, y) -- TODO: remove if transparency added?

        if cursor is list_cursor.ListMenuCursor<BattleMenuContext> then
            draw_floating_menu(x, y, cursor)
        end
    end

    draw_target_manager:draw(draw_x, 0)
    profile("draw_map_post_rows")
    profile("tactics_map_draw")
end

return TacticsMap
