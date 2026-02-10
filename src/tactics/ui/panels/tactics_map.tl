---@brief
--- The UI panel responsible for rendering the entire battle map,
--- including tiles, units, and cursors.

require("profiler")
require("src.tactics.config")

local fp = require("src.tactics.util.fp")
local box = require("src.tactics.ui.box")
local DrawTargetManager = require("src.tactics.draw.draw_target_manager").DrawTargetManager
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local bm = require("src.tactics.battle.battle_map")
local menu_cursor = require("src.tactics.menu.menu_cursor")
local nested_cursor = require("src.tactics.menu.cursor.nested_cursor")
local grid_cursor = require("src.tactics.menu.cursor.grid_cursor")
local BattleMenuContext = require("src.tactics.battle.battle_menu_context").BattleMenuContext
local BattleUIContext = require("src.tactics.battle.battle_ui_context").BattleUIContext
local lists = require("src.tactics.util.lists")
local point = require("src.tactics.util.point")
local Point = point.Point
local battle_unit = require("src.tactics.battle.tactics.battle_unit")
local BattleUnit = battle_unit.BattleUnit
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local vertical_list_menu = require("src.tactics.ui.panels.vertical_list_menu")
local CharacterRenderer = require("src.tactics.character.character_renderer")
local dialogue_node = require("src.tactics.ui.components.dialogue_node")
local array_2d = require("src.tactics.util.array_2d")

local record TacticsMap
    is box.UIElement
    map_width: integer
    map_height: integer
    child_object: any
end
setmetatable(TacticsMap, { __index = box.Box})

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

function tactics_map.new(map_width: integer, map_height: integer, props: box.UIElement): TacticsMap
    local self = box.new(props) as TacticsMap
    setmetatable(self, { __index = TacticsMap})

    self.map_width = map_width or MAP_WIDTH
    self.map_height = map_height or MAP_HEIGHT

    self.w = self.map_width * TILE_SIZE.x + self.internal_margin.l + self.internal_margin.r
    self.h = self.map_height * TILE_SIZE.y + self.internal_margin.t + self.internal_margin.b

    return self
end

local record AnimatedUnitPosition
    id: integer
    point: Point
end

local function get_cursor_tile(battle_context: BattleUIContext): Point
    local menu = battle_context.battle_menu_manager
    local cursor = menu.menu_cursor
    if cursor is grid_cursor.GridMenuNode then
        return cursor.point
    elseif menu.menu_state.point ~= nil then
        return menu.menu_state.point
    end
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

local function should_draw_shadow(unit: BattleUnit, ctx: BattleUIContext): boolean
    if ctx.acting_unit ~= nil and unit.id == ctx.acting_unit.id then
        return true
    end
    if ctx.hovered_unit ~= nil and unit.id == ctx.hovered_unit.id then
        return true
    end
    if unit.marked then
        return true
    end

    return false
end

local function draw_unit(unit: BattleUnit, draw_target_manager: DrawTargetManager, ctx: BattleUIContext)
    local unit_tile = unit.tile
    local draw_shadow = should_draw_shadow(unit, ctx)

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

    CharacterRenderer.draw_health_bar(unit, world_point + FOOT_GROUND_ANCHOR, true, true)
    CharacterRenderer.draw(unit, world_point + FOOT_GROUND_ANCHOR, draw_target_manager, true, true, draw_shadow, look_direction)
end

local function set_ud_tile(ud: Userdata, t: Point, s: integer)
    ud:set(t.x, t.y, BASE_TILE_SPRITE + s)
end

local function get_path_layer(state: UIContextManager): Userdata
    local menu = state.battle_context.battle_menu_manager
    local cursor: menu_cursor.MenuNode = menu.menu_cursor

    local path_layer = pt.userdata("i16", state.battle_context.battle_map.width, state.battle_context.battle_map.height)
    if cursor is grid_cursor.GridMenuNode then
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

function TacticsMap:draw_map_decorations(layers: bm.MapLayers, z_0: integer, z_1: integer)
    local layer_wall_back = layers.terrain.back_wall
    local layer_wall_mid = layers.terrain.mid_wall
    local layer_wall_front = layers.terrain.front_wall

    -- local y_0 = pt.flr(z_0 / t_y)
    -- local y_1 = pt.flr(z_1 / t_y)
    for z=z_0,z_1 do
        --this is kinda dumb
        if z % TILE_HEIGHT == 0 then
            local y = pt.flr(z / TILE_HEIGHT)
            pt.map(layer_wall_back, 0, y, 0, (y - 1) * TILE_HEIGHT, self.map_width, 1, nil, TILE_SIZE.x, TILE_HEIGHT)
        end
        if z % TILE_HEIGHT == HALF_HEIGHT then
            local y = pt.flr(z / TILE_HEIGHT)
            pt.map(layer_wall_mid, 0, y, 0, (y) * TILE_HEIGHT - HALF_HEIGHT, self.map_width, 1, nil, TILE_SIZE.x, TILE_HEIGHT)
        end
        if z % TILE_HEIGHT == 0 then
            local y = pt.flr(z / TILE_HEIGHT)
            pt.map(layer_wall_front, 0, y, 0, (y) * TILE_HEIGHT, self.map_width, 1, nil, TILE_SIZE.x, TILE_HEIGHT)
        end
    end
end

---@desc
--- Dynamically adds or removes a floating menu as a child of the map.
--- The menu appears next to the cursor when the menu state requires it
--- (e.g., for action selection), and is removed otherwise.
function TacticsMap:compute_children(state: UIContextManager)
    local menu = state.battle_context.battle_menu_manager
    local cursor = menu.menu_cursor
    local cursor_tile = get_cursor_tile(state.battle_context)

    local child_object = self.child_object
    local x: integer = 0
    local y: integer = 0
    local menu_box: box.UIElement = nil
    if state.battle_context.active_dialogue ~= nil then
        local unit = state.battle_context.active_dialogue.speaking_unit

        local x_step = unit.facing.horizontal == "left" and -4.5 or 1.5

        x = pt.flr((unit.tile.x + x_step) * TILE_SIZE.x)
        y = pt.flr((unit.tile.y - 0.5) * TILE_SIZE.y)

        local ui_object = state.battle_context.active_dialogue
        if child_object ~= ui_object then
            menu_box = box.new({
                w = 80,
                -- h = 30,
                auto_height = true,
                decoration_padding = 1,
                padding = 2,
                decoration = "border",
            })
        
            local node = dialogue_node.new(
            	{
                    dialogue = state.battle_context.active_dialogue.dialogue,
                    dialogue_mode = "active_line",
                    draw_properties = {
                        wrap = "wrap",
                    },
                    flex_grow = 1,
                    rows = 3,
                    -- internal_margin = { t = y, l = x}
                }
            )
            menu_box:add(node)
            self.child_object = ui_object
        end
    elseif cursor_tile ~= nil then
        x = pt.flr((cursor_tile.x + 1) * TILE_SIZE.x)
        y = pt.flr((cursor_tile.y - 0.5) * TILE_SIZE.y)

        if cursor is list_cursor.ListMenuNode<string> then
            if child_object ~= cursor then
                menu_box = box.new({
                    auto_height = true,
                    auto_width = true,
                    decoration_padding = 1,
                    padding = 2,
                    decoration = "border",
                })
                log.info("Adding list child")
                local node = vertical_list_menu.new(
                    " {text}",
                    ">{text}",
                	function (s: UIContextManager): list_cursor.ListMenuNode<string>
                		local c = s.battle_context.battle_menu_manager.menu_cursor
                		assert(c is list_cursor.ListMenuNode<string>)
                		return c
                	end,
                	{
                        draw_properties = {
                            wrap = "no_wrap",
                        },
                        auto_height = true,
                        auto_width = true,
                        -- internal_margin = { t = y, l = x}
                    }
                )
                menu_box:add(node)
                self.child_object = cursor
            end
        else
            if #self.children ~= 0 then
                log.info("removing list child")
                self.children = {}
                self.child_object = nil
            end
        end
    else
        if #self.children ~= 0 then
            log.info("removing list child")
            self.children = {}
            self.child_object = nil
        end
    end

    if menu_box ~= nil then
        self.children = { box.floating(menu_box, x, y) }
    end
end

---@desc
--- The main rendering function for the entire battle map panel.
--- Draws ground, walls and Z-sorted units, and ceilings from the tile map, as well as UI cursor tiles
--- Prerender to a draw target to handle clipping at the edges.
function TacticsMap:draw(
    state: UIContextManager,
    draw_target_manager: DrawTargetManager,
    ui_theme: UITheme
)
    profile("tactics_map_draw")
    profile("draw_map_pre_rows")
    
    box.Box._draw_background(self, ui_theme)

    local draw_cursor =
        state.game_context.input_service.current_input == "joypad"
        or state.game_context.input_service.current_input == "keyboard"
    
    local map = state.battle_context.battle_map

    local ud_width = self.w - self.internal_margin.l - self.internal_margin.r
    -- to top of screen
    local ud_height = self.h + self.x - self.internal_margin.b
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

    -- TODO: preload layers
    local layers = state.battle_context.battle_map.layers
    local layer_ground = layers.terrain.ground
    profile("compute_path_layer")
    local layer_path = get_path_layer(state)
    profile("compute_path_layer")

    local cursor_tile = get_cursor_tile(state.battle_context)

    -- draw ground
    profile("draw_ground")
    
    pt.map(layer_ground, 0, 0, 0, 0, self.map_width, self.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)

    do
        -- todo: this should be precomputed on mark
        local marked_units = map:get_units(BattleUnit.is_marked)
        local marked_attack_tiles = fp.pipeline_2(
            lists.map(function(u: BattleUnit): Userdata return u.valid_tiles end),
            lists.reduce(
                pt.userdata("u8", state.battle_context.battle_map.width, state.battle_context.battle_map.height),
                function(acc: Userdata, elem: Userdata): Userdata
                    return acc | (elem & 0x4)
            end)
        )(marked_units)

        local hovered_unit = state.battle_context.hovered_unit

        local hovered_unit_tiles: Userdata
        if hovered_unit ~= nil then
            hovered_unit_tiles = hovered_unit.valid_tiles
        end
        -- shouldn't acting unit come from menu manager?
        local acting_unit = state.battle_context.acting_unit
        local tile_interaction_highlights = state.battle_context.battle_map:get_tile_highlights()

        local cursor = state.battle_context.battle_menu_manager.menu_cursor
        local cursor_legal_tiles: array_2d.Array2D<grid_cursor.MenuTileHighlight>
        if cursor is grid_cursor.GridMenuNode then
            cursor_legal_tiles = cursor.legal_tiles
        end

        local highlighted_tiles = pt.userdata("i16", state.battle_context.battle_map.width, state.battle_context.battle_map.height)
        for x = 0, self.map_width-1 do
            for y = 0, self.map_height-1 do
                -- would like to move this logic into the ui context
                if cursor_legal_tiles ~= nil and cursor_legal_tiles:get(x, y) ~= nil and cursor_legal_tiles:get(x, y).valid_selection then
                    highlighted_tiles:set(x, y, 10)
                elseif cursor_legal_tiles ~= nil and cursor_legal_tiles:get(x, y) ~= nil and cursor_legal_tiles:get(x, y).can_attack then
                    highlighted_tiles:set(x, y, 11)
                elseif tile_interaction_highlights:get(x, y) then
                    highlighted_tiles:set(x, y, 15)
                elseif acting_unit == nil
                    and hovered_unit_tiles ~= nil
                    and (hovered_unit_tiles:get(x,y) & 0x5) ~= 0
                then
                    if (hovered_unit_tiles:get(x, y) & 0x1) ~= 0 then
                        highlighted_tiles:set(x, y, 10)
                    elseif (hovered_unit_tiles:get(x, y) & 0x4) ~= 0 then
                        highlighted_tiles:set(x, y, 11)
                    end
                elseif (marked_attack_tiles:get(x, y) & 0x4) ~= 0 then
                    highlighted_tiles:set(x, y, 13)
                end
                
            end
        end

        pt.map(highlighted_tiles, 0, 0, 0, 0, self.map_width, self.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)
    end
    
    pt.map(layer_path, 0, 0, 0, 0, self.map_width, self.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)
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
        profile("draw_map_rows_units")
        local unit_id = sorted_units:get(1, i)
        local unit = map:get_unit_by_id(unit_id)
        local next_z = sorted_units:get(0, i)
        profile("draw_map_rows_units")
        profile("draw_map_rows_decorations")
        if next_z > prev_z then
            self:draw_map_decorations(layers, prev_z, next_z)
            prev_z = next_z
        end
        profile("draw_map_rows_decorations")
        profile("draw_map_rows_units")
        draw_unit(unit, draw_target_manager, state.battle_context)
        profile("draw_map_rows_units")
    end
    self:draw_map_decorations(layers, prev_z, MAP_HEIGHT * TILE_SIZE.y)
    
    profile("draw_map_rows")

    profile("draw_map_post_rows")
    local layer_ceiling = layers.terrain.ceiling
    if layer_ceiling ~= nil then
        pt.map(layer_ceiling, 0, 0, 0, 0, self.map_width, self.map_height, nil, TILE_SIZE.x, TILE_SIZE.y)
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

    draw_target_manager:draw(draw_x, 0)
    profile("draw_map_post_rows")
    profile("tactics_map_draw")

    box.Box._draw_children(self, state, draw_target_manager, ui_theme)
end

-- TODO: consider using unit sprite masks for more accurate grid selection
function TacticsMap:get_selection_at(
    lx: number,
    ly: number
): mouse_menu_selection.MenuMouseSelection
    local tx = pt.flr((lx-self.internal_margin.l) / TILE_WIDTH)
    local ty = pt.flr((ly-self.internal_margin.t) / TILE_HEIGHT)

    if tx >= 0 and tx < MAP_WIDTH
        and ty >= 0 and ty < MAP_HEIGHT
    then
        return mouse_menu_selection.grid(tx, ty)
    end
    return nil
end

return tactics_map
