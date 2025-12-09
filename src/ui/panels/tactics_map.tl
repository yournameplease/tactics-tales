require("src/debug")
require("src/config")

require("src/ui/box")
require("src/menu/battle_menu_manager")
require("src/ui/ui_context_manager")
require("src/battle/battle_state")

local CharacterRenderer = require("src/character/character_renderer")

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

-- UNIT offset should instead be the feet position, and draw using skeleton position
local UNIT_OFFSET_Y = -3
local CURSOR_SPRITE = 8

local TEXT_HEIGHT = 7

local FOOT_GROUND_ANCHOR = AnimationAnchorPoint.of(8,12)

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
    point: WorldPoint
end

local function compute_animated_unit_positions(battle_state: BattleState): { AnimatedUnitPosition }
    return tmap(
            battle_state:get_all_units(),
            function(unit: BattleUnit): AnimatedUnitPosition
                local animation_offset = CharacterRenderer.get_animation_offset(unit)
                return {
                    id = unit.id,
                    point = (unit.tile * TILE_SIZE + animation_offset) as WorldPoint,
                }
            end
    )
end

local function draw_health_bar(hp_current: integer, hp_max: integer, x: integer, y: integer, width: integer, height: integer)
    rrectfill(x, y, width, height, 1, COLOR_MENU_PRIMARY)
    local bar_width = flr(hp_current*(width-2) / hp_max)
    rrectfill(x+1, y+1, bar_width, height-2, 1, 27)
    rrect(x, y, width, height, 1, COLOR_MENU_SECONDARY)
end

local function draw_floating_menu(x: integer, y: integer, menu_selection: VerticalListMenuSelection)
    local selected_i = menu_selection.i
    local options = menu_selection.options
    local PADDING = 2

    local max_text_width = 0
    for _,opt in ipairs(options) do
        local text_width = print(opt.text, 0, -1000) as integer
        max_text_width = max(max_text_width, text_width)
    end

    local menu_x = x + TILE_SIZE.x
    local menu_y = y + TILE_SIZE.y
    local menu_w = 2*PADDING + max_text_width
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

local function draw_unit(unit: BattleUnit)
    local side = unit.side
    local unit_tile = unit.tile
    -- local has_acted = unit.has_acted

    local world_point = unit_tile * TILE_SIZE

    -- local shadow_color
    -- if has_acted then
    --     shadow_color = 0
    -- else
    --     shadow_color = 7
    -- end
    --draw_shadow(shadow_color,
    --        function(draw_x,draw_y) unit:draw(draw_x, draw_y, side, false) end,
    --        tile_x + UNIT_OFFSET_X, tile_y + UNIT_OFFSET_Y)

    CharacterRenderer.draw(unit, world_point + FOOT_GROUND_ANCHOR, side, true, true)

    local hp_current = unit.hp_current
    local hp_max = unit.character.stats.hp_max
    -- TODO: make this a skeleton point
    draw_health_bar(hp_current, hp_max, world_point.x+1, world_point.y+UNIT_OFFSET_Y-5, TILE_SIZE.x-2, 4)
end

function TacticsMap:draw(state: UIContextManager, ui_theme: UITheme)
    Box._draw(self, state, ui_theme)

    local battle_state = state.battle_ui_context.battle_state
    local menu = state.battle_ui_context.battle_menu_manager

    local camera_x = self.x + self.internal_margin.l
    local camera_y = self.y + self.internal_margin.t
    camera(-camera_x, -camera_y)

    -- draw row-by row, top to bottom aka back to front

    -- pre-compute actor animations for z-ordering
    local unit_positions = compute_animated_unit_positions(state.battle_ui_context.battle_state)

    local sorted_units = userdata("i16", 2, #unit_positions)
    for i,u in ipairs(unit_positions) do
        sorted_units:set(0,i-1, u.point.y)
        sorted_units:set(1,i-1, u.id)
    end
    sorted_units:sort()

    local drawn_unit_count = 0
    -- TODO: preload layers
    local layers = state.battle_ui_context.tile_manager.map_data.layers
    local layer_ground = layers.ground
    local layer_wall_back = layers.back_wall
    local layer_wall_mid = layers.mid_wall
    local layer_wall_front = layers.front_wall

    local cursor_tile: TilePoint = nil
    local menu_selection = menu.menu_selection
    if menu_selection is GridMenuSelection then
        cursor_tile = menu_selection.point
    elseif menu.menu_state.point ~= nil then
        cursor_tile = menu.menu_state.point
    end

    for y = 0, self.map_height-1 do
        map(layer_wall_back, 0, y, 0, (y-1) * TILE_SIZE.y, self.map_width, 1, nil, TILE_SIZE.x, TILE_SIZE.y)
        map(layer_ground, 0, y, 0, y * TILE_SIZE.y, self.map_width, 1, nil, TILE_SIZE.x, TILE_SIZE.y)

        -- highlight legal tiles
        if menu_selection is GridMenuSelection then
            if menu_selection.legal_tiles ~= nil then
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
                for x = 0, self.map_width-1 do
                    local highlighted_tile = menu_selection.legal_tiles:get(x, y)
                    if highlighted_tile ~= nil and (highlighted_tile.reachable or highlighted_tile.can_attack)  then
                        if (highlighted_tile.reachable) then
                            color(28)
                        elseif highlighted_tile.can_attack then
                            color(8)
                        else
                            error("invalid state")
                        end
                        rrectfill(x*TILE_SIZE.x+1, y*TILE_SIZE.y+1, TILE_SIZE.x-2, TILE_SIZE.y-2)
                    end
                end
                poke(0x550b,0x00)
                fillp()
                color()
            end
        end

        while drawn_unit_count < #unit_positions and sorted_units:get(0, drawn_unit_count) <= (y) * TILE_SIZE.y + HALF_HEIGHT do
            local unit_id = sorted_units:get(1, drawn_unit_count)
            local unit = battle_state:get_unit_by_id(unit_id)
            draw_unit(unit)
            drawn_unit_count = drawn_unit_count + 1
        end

        map(layer_wall_mid, 0, y, 0, y * TILE_SIZE.y - HALF_HEIGHT, self.map_width, 1, nil, TILE_SIZE.x, TILE_SIZE.y)

        while drawn_unit_count < #unit_positions and sorted_units:get(0, drawn_unit_count) <= (y+1) * TILE_SIZE.y do
            local unit_id = sorted_units:get(1, drawn_unit_count)
            local unit = battle_state:get_unit_by_id(unit_id)
            draw_unit(unit)
            drawn_unit_count = drawn_unit_count + 1
        end

        -- TODO: this is better with transparency
        if cursor_tile ~= nil then
            local c_x = cursor_tile.x * TILE_SIZE.x
            local c_y = cursor_tile.y * TILE_SIZE.y
            spr(CURSOR_SPRITE, c_x, c_y)
        end

        map(layer_wall_front, 0, y, 0, y * TILE_SIZE.y, self.map_width, 1, nil, TILE_SIZE.x, TILE_SIZE.y)
    end

    if cursor_tile ~= nil then
        local x = cursor_tile.x * TILE_SIZE.x
        local y = cursor_tile.y * TILE_SIZE.y
        spr(CURSOR_SPRITE, x, y) -- TODO: remove if transparency added?

        if menu_selection is VerticalListMenuSelection then
            draw_floating_menu(x, y, menu_selection)
        end
    end

    camera()
end

return TacticsMap
