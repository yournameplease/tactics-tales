---@brief
--- The UI panel responsible for rendering the entire battle map,
--- including tiles, units, and cursors.

local box = require("src.tactics.ui.box")
local lists = require("src.tactics.util.lists")
local point = require("src.tactics.util.point")
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local CharacterRenderer = require("src.tactics.character.character_renderer")
local colors = require("src.tactics.colors")

---@class MapData
---@field menu_node? MenuNode
---@field camera_x? integer
---@field camera_y? integer
---@field map_width? integer
---@field map_height? integer

local tactics_map = {}

local VIEWPORT_WIDTH = STATIC_CONFIG.VIEWPORT_WIDTH
local VIEWPORT_HEIGHT = STATIC_CONFIG.VIEWPORT_HEIGHT
local TILE_WIDTH = STATIC_CONFIG.TILE_WIDTH
local TILE_HEIGHT = STATIC_CONFIG.TILE_HEIGHT
local TILE_SIZE = point.of(TILE_WIDTH, TILE_HEIGHT)
local HALF_HEIGHT = TILE_HEIGHT >> 1
local BASE_TILE_SPRITE = 2 * 256

local CURSOR_SPRITE = 8

local FOOT_GROUND_ANCHOR = point.of(8, 12)
local ICON_ANCHOR = point.of(4, -8)

---@class AnimatedUnitPosition
---@field id integer
---@field point Point

---@param map BattleMap
---@return AnimatedUnitPosition[]
local function compute_animated_unit_positions(map)
    return lists.map(
        function(unit)
            local animation_offset = CharacterRenderer.get_animation_offset(unit)
            return {
                id = unit.id,
                point = unit.tile * TILE_SIZE + animation_offset,
            }
        end
    )(map:get_all_units())
end

---comment
---@param unit BattleUnit
---@param animated_position Point
---@param camera Point
---@param draw_target_manager DrawTargetManager
---@param ui_theme UITheme
local function draw_unit(
    unit,
    animated_position,
    camera,
    draw_target_manager,
    ui_theme
)
    local world_point = unit.tile * TILE_SIZE
    local draw_point = world_point + FOOT_GROUND_ANCHOR - camera

    CharacterRenderer.draw_health_bar(unit, draw_point, true, true, ui_theme)
    CharacterRenderer.draw(unit, draw_point, draw_target_manager, true, true, true, nil)

    -- TODO: these should check objective instead
    local animated_sprite_point = animated_position + ICON_ANCHOR
    if unit.tags["hero"] then
        spr(128, animated_sprite_point.x, animated_sprite_point.y)
    end
    if unit.tags["boss"] then
        spr(129, animated_sprite_point.x, animated_sprite_point.y)
    end
end

---@param ud userdata_2d
---@param t Point
---@param s integer
local function set_ud_tile(ud, t, s)
    ud:set(t.x, t.y, BASE_TILE_SPRITE + s)
end

--- return a userdata containing a map of the active menu's path, if present
---@param state UIContextManager
---@return userdata_2d
local function get_path_layer(state)
    local path_layer = userdata("i16", state.battle_context.battle_map.width, state.battle_context.battle_map.height)
    local path = state.battle_context.hovered_path
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
            for i = 2, #path - 1 do
                local step_offset = path[i + 1] - path[i - 1]
                local one_step_offset = path[i] - path[i - 1]
                local s = 0
                if step_offset.x == 0 then
                    s = 193
                elseif step_offset.y == 0 then
                    s = 192
                else
                    local dir = step_offset.x * step_offset.y -- +/- 1
                    if dir == 1 then                          -- 45 deg down
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
                local step_offset = path[#path] - path[#path - 1]
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


--- Draw front/back/mid map layers between z_0 and z_1
---@param layers MapLayers
---@param z_0 integer
---@param z_1 integer
---@param tile_ox integer First visible tile column
---@param px integer Sub-tile pixel x shift
---@param camera_y integer Camera top-edge in world pixels
---@param draw_w integer Horizontal tile count to draw
local function draw_map_decorations(layers, z_0, z_1, tile_ox, px, camera_y, draw_w)
    local layer_wall_back = layers.terrain.back_wall
    local layer_wall_mid = layers.terrain.mid_wall
    local layer_wall_front = layers.terrain.front_wall

    for z = z_0, z_1 do
        if z % TILE_HEIGHT == 0 then
            local y = flr(z / TILE_HEIGHT)
            map(layer_wall_back, tile_ox, y, px, (y - 1) * TILE_HEIGHT - camera_y, draw_w, 1, nil, TILE_SIZE.x,
                TILE_HEIGHT)
        end
        if z % TILE_HEIGHT == HALF_HEIGHT then
            local y = flr(z / TILE_HEIGHT)
            map(layer_wall_mid, tile_ox, y, px, y * TILE_HEIGHT - HALF_HEIGHT - camera_y, draw_w, 1, nil, TILE_SIZE.x,
                TILE_HEIGHT)
        end
        if z % TILE_HEIGHT == 0 then
            local y = flr(z / TILE_HEIGHT)
            map(layer_wall_front, tile_ox, y, px, y * TILE_HEIGHT - camera_y, draw_w, 1, nil, TILE_SIZE.x, TILE_HEIGHT)
        end
    end
end

--- The main rendering function for the entire battle map panel.
--- Draws ground, walls and Z-sorted units, and ceilings from the tile map, as well as UI cursor tiles
--- Prerender to a draw target to handle clipping at the edges.
---@param self UIElement
---@param state UIContextManager
---@param draw_target_manager DrawTargetManager
---@param ui_theme UITheme
local function draw_tactics_map(
    self,
    state,
    draw_target_manager,
    ui_theme
)
    profile("tactics_map_draw")
    profile("draw_map_pre_rows")

    local draw_cursor =
        state.game_context.input_service.current_input == "joypad"

    local battle_map = state.battle_context.battle_map
    local camera_x = state.battle_context.camera_x
    local camera_y = state.battle_context.camera_y

    -- Tile and sub-tile offsets for camera scrolling
    local tile_ox = flr(camera_x / TILE_WIDTH)
    local tile_oy = flr(camera_y / TILE_HEIGHT)
    local px = -(camera_x % TILE_WIDTH)
    local py = -(camera_y % TILE_HEIGHT)
    local draw_w = VIEWPORT_WIDTH + 1
    local draw_h = VIEWPORT_HEIGHT + 1

    local ud_width = self.rect.c_w
    -- to top of screen
    local ud_height = self.rect.c_h + self.layout.padding.t
    local padding_top = self.layout.padding.t
    local draw_x = self.rect.c_x
    local draw_y = self.rect.y
    draw_target_manager:push_target(ud_width, ud_height, 0, padding_top)

    -- draw row-by row, top to bottom aka back to front

    -- pre-compute actor animations for z-ordering; cull units outside viewport
    local vis_min_x = camera_x - TILE_WIDTH
    local vis_max_x = camera_x + VIEWPORT_WIDTH * TILE_WIDTH + TILE_WIDTH
    local vis_min_y = camera_y - TILE_HEIGHT
    local vis_max_y = camera_y + VIEWPORT_HEIGHT * TILE_HEIGHT + TILE_HEIGHT

    local all_positions = compute_animated_unit_positions(battle_map)
    local unit_positions = {}
    for _, u in ipairs(all_positions) do
        if u.point.x >= vis_min_x and u.point.x <= vis_max_x
            and u.point.y >= vis_min_y and u.point.y <= vis_max_y
        then
            table.insert(unit_positions, u)
        end
    end

    local sorted_units = userdata("i16", 3, #unit_positions)
    if sorted_units then
        for i, u in ipairs(unit_positions) do
            sorted_units:set(0, i - 1, u.point.y - camera_y)
            sorted_units:set(1, i - 1, u.point.x - camera_x)
            sorted_units:set(2, i - 1, u.id)
        end
    end
    -- Only sort if > 1 unit.  Sorting a single row will consider it a 1-d userdata
    if #unit_positions > 1 then
        sorted_units:sort()
    end

    -- TODO: preload layers
    local layers = battle_map.layers
    local layer_ground = layers.terrain.ground
    -- todo: move to ui context
    local layer_path = get_path_layer(state)

    local cursor_tile = state.battle_context.hovered_point

    -- draw ground
    profile("draw_ground")

    -- TODO: clipping is important for scrolling maps.  currently bugged
    -- local clip_w = VIEWPORT_WIDTH * TILE_WIDTH
    -- local clip_h = VIEWPORT_HEIGHT * TILE_HEIGHT
    -- clip(0, self.rect.c_y, clip_w, clip_h)
    map(layer_ground, tile_ox, tile_oy, px, py, draw_w, draw_h, nil, TILE_SIZE.x, TILE_SIZE.y)

    local checkerboard_layer = userdata("i16", state.battle_context.battle_map.width,
        state.battle_context.battle_map.height)
    for x = 0, battle_map.width do
        for y = x % 2, battle_map.height, 2 do
            checkerboard_layer:set(x, y, 192)
        end
    end
    colors.apply_colortable_row("dark")
    map(checkerboard_layer, tile_ox, tile_oy, px, py, draw_w, draw_h, nil, TILE_SIZE.x, TILE_SIZE.y)


    for _, decoration_layer in ipairs(layers.decorations or {}) do
        map(decoration_layer, tile_ox, tile_oy, px, py, draw_w, draw_h, nil, TILE_SIZE.x, TILE_SIZE.y)
    end

    map(state.battle_context.highlighted_tiles, tile_ox, tile_oy, px, py, draw_w, draw_h, nil, TILE_SIZE.x, TILE_SIZE.y)

    map(layer_path, tile_ox, tile_oy, px, py, draw_w, draw_h, nil, TILE_SIZE.x, TILE_SIZE.y)
    -- TODO: this is better with transparency
    if draw_cursor and cursor_tile ~= nil then
        local c_x = cursor_tile.x * TILE_SIZE.x - camera_x
        local c_y = cursor_tile.y * TILE_SIZE.y - camera_y
        spr(CURSOR_SPRITE, c_x, c_y)
    end
    clip()
    profile("draw_ground")
    profile("draw_map_pre_rows")

    profile("draw_map_rows")
    local prev_z = camera_y
    for i = 0, #unit_positions - 1 do
        local unit_id = sorted_units:get(2, i)
        local unit = battle_map:get_unit_by_id(unit_id)
        if unit then
            local next_z = sorted_units:get(0, i) + camera_y
            local next_x = sorted_units:get(1, i)
            if next_z > prev_z then
                draw_map_decorations(layers, prev_z, next_z, tile_ox, px, camera_y, draw_w)
                prev_z = next_z
            end
            local animated_point = point.of(next_x, next_z - camera_y)
            local camera = point.of(camera_x, camera_y)
            draw_unit(unit, animated_point, camera, draw_target_manager, ui_theme)
        else
            log.warn("Unit not found while drawing. This is likely a bug.")
        end
    end
    draw_map_decorations(layers, prev_z, battle_map.height * TILE_SIZE.y, tile_ox, px, camera_y, draw_w)

    profile("draw_map_rows")

    profile("draw_map_post_rows")
    local layer_ceiling = layers.terrain.ceiling
    if layer_ceiling ~= nil then
        map(layer_ceiling, tile_ox, tile_oy, px, py, draw_w, draw_h, nil, TILE_SIZE.x, TILE_SIZE.y)
    end

    if cursor_tile ~= nil then
        local x = cursor_tile.x * TILE_SIZE.x - camera_x
        local y = cursor_tile.y * TILE_SIZE.y - camera_y
        if draw_cursor then
            spr(CURSOR_SPRITE, x, y) -- TODO: remove if transparency added?
        end
    end

    draw_target_manager:draw(draw_x, draw_y)

    local banner = state.battle_context.tactics_engine.phase_banner
    if banner then
        -- todo: move to a proper flexbox
        local sw = self.rect.c_w
        local sh = self.rect.c_h
        local bw, bh = 160, 24
        local bx = (sw - bw) / 2 + self.rect.c_x
        local by = (sh - bh) / 2 + self.rect.c_y

        local c1 = ui_theme.COLOR_INTERIOR
        local c2 = ui_theme.COLOR_PAGE_DECOR
        local c3 = ui_theme.COLOR_INTERIOR_TEXT
        rectfill(bx, by, bx + bw, by + bh, c1)
        rect(bx + 1, by + 1, bx + bw - 1, by + bh - 1, c2)
        print(banner.text, bx + 8, by + 8, c3)
    end

    profile("draw_map_post_rows")
    profile("tactics_map_draw")
end

-- TODO: consider using unit sprite masks for more accurate grid selection
---@param self UIElement
---@param lx number
---@param ly number
---@return MenuMouseSelection?
local function get_selection_at(
    self,
    lx,
    ly
)
    ---@type MapData
    local data = self.data
    local cam_x = data.camera_x or 0
    local cam_y = data.camera_y or 0
    local tx = flr((lx + cam_x) / TILE_WIDTH)
    local ty = flr((ly + cam_y) / TILE_HEIGHT)

    if data.menu_node then
        local map_w = data.map_width or VIEWPORT_WIDTH
        local map_h = data.map_height or VIEWPORT_HEIGHT
        if tx >= 0 and tx < map_w
            and ty >= 0 and ty < map_h
        then
            return mouse_menu_selection.grid(
                tx, ty,
                data.menu_node,
                "select", "menu")
        end
    end
    return nil
end

---comment
---@return UIElement
function tactics_map.new()
    local c_w = VIEWPORT_WIDTH * TILE_SIZE.x
    local c_h = VIEWPORT_HEIGHT * TILE_SIZE.y

    ---@type MapData
    local map_data = {}

    local self = box.builder("tactics_map")
        :data(map_data)
        :layout {
            padding = {
                t = 5,
                b = 5,
                l = 4,
                r = 4,
            },
            width = c_w + 4 + 4,
            height = c_h + 5 + 5,
        }
        :style {
            decoration_padding = 2,
            solid = true,
            decoration = "border",
        }
        :menu_handling {
            get_selection_at = get_selection_at,
        }
        :on_draw(draw_tactics_map)
        :on_update(function(self, state)
            local data = self.data
            local menu_step = state.battle_context.battle_menu_manager.menu_step
            data.menu_node = menu_step and menu_step.node or nil
            data.camera_x = state.battle_context.camera_x
            data.camera_y = state.battle_context.camera_y
            data.map_width = state.battle_context.battle_map.width
            data.map_height = state.battle_context.battle_map.height

            if state.game_context.input_service.current_input == "mouse" then
                local m = state.game_context.input_service:get_mouse()
                local lx = m.mx - (self.rect.c_x or 0)
                local ly = m.my - (self.rect.c_y or 0)
                local vp_w = VIEWPORT_WIDTH * TILE_WIDTH
                local vp_h = VIEWPORT_HEIGHT * TILE_HEIGHT
                local border = STATIC_CONFIG.CAMERA_EDGE_SCROLL_BORDER
                local speed = STATIC_CONFIG.CAMERA_EDGE_SCROLL_SPEED
                local bctx = state.battle_context

                if bctx then
                    if lx >= 0 and lx < border then
                        bctx.camera_x = bctx.camera_x - speed
                    elseif lx >= vp_w - border and lx < vp_w then
                        bctx.camera_x = bctx.camera_x + speed
                    end
                    if ly >= 0 and ly < border then
                        bctx.camera_y = bctx.camera_y - speed
                    elseif ly >= vp_h - border and ly < vp_h then
                        bctx.camera_y = bctx.camera_y + speed
                    end
                    bctx:clamp_camera(bctx.battle_map)
                end
            end
        end)
        :build()

    return self
end

return tactics_map
