---@brief
--- The UI panel responsible for rendering the entire battle map,
--- including tiles, units, and cursors.

require("profiler")
require("src.tactics.config")

local box = require("src.tactics.ui.box")
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local bm = require("src.tactics.battle.battle_map")
local BattleUIContext = require("src.tactics.battle.battle_ui_context").BattleUIContext
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNode = menu_cursor.MenuNode
local lists = require("src.tactics.util.lists")
local point = require("src.tactics.util.point")
local Point = point.Point
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local CharacterRenderer = require("src.tactics.character.character_renderer")


local record MapData
    map_width: integer
    map_height: integer
    menu_node: MenuNode
end

local tactics_map = {}

local MAP_WIDTH = STATIC_CONFIG.MAP_WIDTH
local MAP_HEIGHT = STATIC_CONFIG.MAP_HEIGHT
local TILE_WIDTH = STATIC_CONFIG.TILE_WIDTH
local TILE_HEIGHT = STATIC_CONFIG.TILE_HEIGHT
local TILE_SIZE = point.of(TILE_WIDTH, TILE_HEIGHT)
local HALF_HEIGHT = TILE_HEIGHT >> 1
local BASE_TILE_SPRITE = 2 * 256

local CURSOR_SPRITE = 8

local FOOT_GROUND_ANCHOR = point.of(8,12)

local record AnimatedUnitPosition
    id: integer
    point: Point
end

local function get_cursor_tile(battle_context: BattleUIContext): Point
    return battle_context.hovered_point
end

local function compute_animated_unit_positions(map: bm.BattleMap): { AnimatedUnitPosition }
    return lists.map(
            function(unit: BattleUnit): AnimatedUnitPosition
                local animation_offset = CharacterRenderer.get_animation_offset(unit)
                return {
                    id = unit.id,
                    point = unit.tile * TILE_SIZE + animation_offset,
                }
            end
    )(map:get_all_units())
end

local function draw_unit(unit: BattleUnit, draw_target_manager: DrawTargetManager, _ctx: BattleUIContext)
    local unit_tile = unit.tile

    local world_point = unit_tile * TILE_SIZE
    local look_direction: CharacterRenderer.LookDirection = nil
    -- local cursor_tile = get_cursor_tile(ctx)
    -- Disabled looking as it's a bit annoyoing to look at
    -- local cursor_tile = get_cursor_tile(ctx)
    -- if cursor_tile ~= nil then
    --     if point.taxicab_distance(cursor_tile, unit_tile) <= 2
    --         or (ctx.acting_unit ~= nil and ctx.acting_unit.id == unit.id)
    --     then
    --         local delta = cursor_tile.x - unit_tile.x
    --         if delta > 0 then
    --             look_direction = "right"
    --         elseif delta < 0 then
    --             look_direction = "left"
    --         end
    --     end
    -- end

    local draw_point = world_point + FOOT_GROUND_ANCHOR

    CharacterRenderer.draw_health_bar(unit, draw_point, true, true)
    CharacterRenderer.draw(unit, draw_point, draw_target_manager, true, true, true, look_direction)

    -- TODO: these should check objective instead    
	if unit.tags["hero"] then
		pt.spr(128, draw_point.x, world_point.y)
	end
	if unit.tags["boss"] then
		pt.spr(129, draw_point.x, world_point.y)
	end
end

local function set_ud_tile(ud: Userdata, t: Point, s: integer)
    ud:set(t.x, t.y, BASE_TILE_SPRITE + s)
end

local function get_path_layer(state: UIContextManager): Userdata
    local path_layer = pt.userdata("i16", state.battle_context.battle_map.width, state.battle_context.battle_map.height)
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
        return path_layer
    end
end

local function draw_map_decorations(self: box.UIElement, layers: bm.MapLayers, z_0: integer, z_1: integer)
    local data: MapData = self.data as MapData

    local layer_wall_back = layers.terrain.back_wall
    local layer_wall_mid = layers.terrain.mid_wall
    local layer_wall_front = layers.terrain.front_wall

    -- local y_0 = pt.flr(z_0 / t_y)
    -- local y_1 = pt.flr(z_1 / t_y)
    for z=z_0,z_1 do
        --this is kinda dumb
        if z % TILE_HEIGHT == 0 then
            local y = pt.flr(z / TILE_HEIGHT)
            pt.map(layer_wall_back, 0, y, 0, (y - 1) * TILE_HEIGHT, data.map_width, 1, nil, TILE_SIZE.x, TILE_HEIGHT)
        end
        if z % TILE_HEIGHT == HALF_HEIGHT then
            local y = pt.flr(z / TILE_HEIGHT)
            pt.map(layer_wall_mid, 0, y, 0, (y) * TILE_HEIGHT - HALF_HEIGHT, data.map_width, 1, nil, TILE_SIZE.x, TILE_HEIGHT)
        end
        if z % TILE_HEIGHT == 0 then
            local y = pt.flr(z / TILE_HEIGHT)
            pt.map(layer_wall_front, 0, y, 0, (y) * TILE_HEIGHT, data.map_width, 1, nil, TILE_SIZE.x, TILE_HEIGHT)
        end
    end
end

---@desc
--- The main rendering function for the entire battle map panel.
--- Draws ground, walls and Z-sorted units, and ceilings from the tile map, as well as UI cursor tiles
--- Prerender to a draw target to handle clipping at the edges.
local function draw_tactics_map(
    self: box.UIElement,
    state: UIContextManager,
    draw_target_manager: DrawTargetManager,
    _ui_theme: UITheme
)
    profile("tactics_map_draw")
    profile("draw_map_pre_rows")

    local data: MapData = self.data as MapData

    local draw_cursor =
        state.game_context.input_service.current_input == "joypad"
    
    local map = state.battle_context.battle_map

    local ud_width = self.rect.c_w
    -- to top of screen
    local ud_height = self.rect.c_h + self.layout.padding.t
    local padding_top = self.layout.padding.t
    local draw_x = self.rect.c_x
    local draw_y = self.rect.y
    draw_target_manager:push_target(ud_width, ud_height, 0, padding_top)

    -- draw row-by row, top to bottom aka back to front

    -- pre-compute actor animations for z-ordering
    local unit_positions = compute_animated_unit_positions(state.battle_context.battle_map)

    local sorted_units = pt.userdata("i16", 2, #unit_positions) as Userdata
    for i,u in ipairs(unit_positions) do
        sorted_units:set(0,i-1, u.point.y)
        sorted_units:set(1,i-1, u.id)
    end
    sorted_units:sort()

    -- TODO: preload layers
    local layers = state.battle_context.battle_map.layers
    local layer_ground = layers.terrain.ground
    -- todo: move to ui context
    local layer_path = get_path_layer(state)

    local cursor_tile = get_cursor_tile(state.battle_context)

    -- draw ground
    profile("draw_ground")
    
    pt.map(layer_ground, 0, 0, 0, 0, data.map_width, data.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)

    pt.map(state.battle_context.highlighted_tiles, 0, 0, 0, 0, data.map_width, data.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)
    
    pt.map(layer_path, 0, 0, 0, 0, data.map_width, data.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)
    -- TODO: this is better with transparency
    if draw_cursor and cursor_tile ~= nil then
        local c_x = cursor_tile.x * TILE_SIZE.x
        local c_y = cursor_tile.y * TILE_SIZE.y
        pt.spr(CURSOR_SPRITE, c_x, c_y)
    end
    profile("draw_ground")
    profile("draw_map_pre_rows")
    
    profile("draw_map_rows")
    local prev_z = 0
    for i=0,#unit_positions-1 do
        -- profile("draw_map_rows_get_unit")
        local unit_id = sorted_units:get(1, i)
        local unit = map:get_unit_by_id(unit_id)
        local next_z = sorted_units:get(0, i)
        -- profile("draw_map_rows_get_unit")
        -- profile("draw_map_rows_decorations")
        if next_z > prev_z then
            draw_map_decorations(self, layers, prev_z, next_z)
            prev_z = next_z
        end
        -- profile("draw_map_rows_decorations")
        -- profile("draw_map_rows_units")
        draw_unit(unit, draw_target_manager, state.battle_context)
        -- profile("draw_map_rows_units")
    end
    draw_map_decorations(self, layers, prev_z, MAP_HEIGHT * TILE_SIZE.y)
    
    profile("draw_map_rows")

    profile("draw_map_post_rows")
    local layer_ceiling = layers.terrain.ceiling
    if layer_ceiling ~= nil then
        pt.map(layer_ceiling, 0, 0, 0, 0, data.map_width, data.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)
    end

    if cursor_tile ~= nil then
        local x = cursor_tile.x * TILE_SIZE.x
        local y = cursor_tile.y * TILE_SIZE.y
        if draw_cursor then
            pt.spr(CURSOR_SPRITE, x, y) -- TODO: remove if transparency added?
        end

        -- if cursor is list_cursor.ListMenuNode<string> then
        --     draw_floating_menu(x, y, cursor)
        -- end
    end

    draw_target_manager:draw(draw_x, draw_y)
    profile("draw_map_post_rows")
    profile("tactics_map_draw")
end

-- TODO: consider using unit sprite masks for more accurate grid selection
local function get_selection_at(
    self: box.UIElement,
    lx: number,
    ly: number
): mouse_menu_selection.MenuMouseSelection
    local data: MapData = self.data as MapData
    local tx = pt.flr(lx / TILE_WIDTH)
    local ty = pt.flr(ly / TILE_HEIGHT)

    if data.menu_node then
        if tx >= 0 and tx < MAP_WIDTH
            and ty >= 0 and ty < MAP_HEIGHT
        then
            return mouse_menu_selection.grid(
                tx, ty,
                data.menu_node,
                "button_primary", "button_secondary")
        end
    end
    return nil
end

function tactics_map.new(map_width: integer, map_height: integer): box.UIElement
    local c_w = map_width * TILE_SIZE.x
    local c_h = map_height * TILE_SIZE.y

    local map_data: MapData = {
        map_width = map_width,
        map_height = map_height,
    }

    local self = box.builder("tactics_map")
    :data(map_data)
    :layout{
        padding = {
            t = 5,
            b = 5,
            l = 4,
            r = 4,
        },
        width = c_w + 4 + 4,
        height = c_h + 5 + 5,
    }
    :style{
        decoration_padding = 2,
        solid = true,
        decoration = "border",
    }
    :menu_handling{
        get_selection_at = get_selection_at,
    }
    :on_draw(draw_tactics_map)
    :on_update(function(self: box.UIElement, state: UIContextManager)
        local data: MapData = self.data as MapData
        local menu_step = state.battle_context.battle_menu_manager.menu_step
        data.menu_node = menu_step and menu_step.node or nil
    end)
    :build()

    return self
end

return tactics_map
