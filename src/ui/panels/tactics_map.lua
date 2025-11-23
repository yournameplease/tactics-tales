Box = include "src/ui/box.lua"

local TacticsMap = {}

local MAP_WIDTH = CONFIG.MAP_WIDTH
local MAP_HEIGHT = CONFIG.MAP_WIDTH
local TILE_WIDTH = CONFIG.TILE_WIDTH
local TILE_HEIGHT = CONFIG.TILE_HEIGHT
local WALL_HEIGHT = CONFIG.WALL_HEIGHT

function TacticsMap:draw(state)
    Box.draw(self, state)

    camera(-MAP_OFFSET_X, -MAP_OFFSET_Y)

    -- draw row-by row, top to bottom aka back to front

    -- TODO: preload layers
    local layers = fetch("map/0.map")
    local layer_ground = layers[2].bmp
    local layer_wall = layers[1].bmp
    local wall_offset = WALL_HEIGHT - TILE_HEIGHT
    for y = 0, MAP_HEIGHT-1 do
        map(layer_ground, 0, y, 0, y * TILE_HEIGHT, MAP_WIDTH, 1, nil, TILE_WIDTH, TILE_HEIGHT)


        -- highlight legal tiles
        --if menu_state.legal_tiles ~= nil then
        --    fillp(
        --    -- 1:2 diagonal slashes
        --    --0b00111111,
        --    --0b11111100,
        --    --0b11110011,
        --    --0b11001111,
        --    --0b00111111,
        --    --0b11111100,
        --    --0b11110011,
        --    --0b11001111
        --    -- 1:2 checkerboard
        --            0x33,
        --            0xCC,
        --            0x33,
        --            0xCC,
        --            0x33,
        --            0xCC,
        --            0x33,
        --            0xCC
        --    )
        --    poke(0x550b,0x3f)
        --    palt()
        --    color(28)
        --    for x = 0, MAP_WIDTH-1 do
        --        if menu_state.legal_tiles[x] ~= nil and menu_state.legal_tiles[x][y] then
        --            rrectfill(x*TILE_WIDTH, y*TILE_HEIGHT, TILE_WIDTH, TILE_HEIGHT)
        --        end
        --    end
        --    poke(0x550b,0x00)
        --    fillp()
        --    color()
        --end

        for x = 0, MAP_WIDTH-1 do
            if self.tile_contents[x][y] ~= nil then
                draw_unit(self:get_unit_at_coordinates(x, y))
            end
        end
        map(layer_wall, 0, y, 0, y * TILE_HEIGHT - wall_offset, MAP_WIDTH, 1, nil, TILE_WIDTH, WALL_HEIGHT)
    end

    --if menu_selection.x ~= nil and menu_selection.y ~= nil then
    --    local x = menu_selection.x * TILE_WIDTH
    --    local y = menu_selection.y * TILE_HEIGHT
    --    spr(CURSOR_SPRITE, x, y)
    --
    --    if menu_state.kind == "CURSOR_VERTICAL_LIST" then
    --        local selected_i = menu_selection.i
    --        local options = menu_state.options
    --        local PADDING = 2
    --
    --        local menu_x = x + TILE_WIDTH
    --        local menu_y = y + TILE_HEIGHT
    --        local menu_w = 2*PADDING + 30
    --        local menu_h = 2*PADDING + #options * (TEXT_HEIGHT+1) -1
    --        rrectfill(menu_x, menu_y, menu_w, menu_h, 1, COLOR_MENU_PRIMARY)
    --        for i,opt in ipairs(options) do
    --            if i == selected_i then
    --                rrectfill(menu_x, menu_y+PADDING-1+(TEXT_HEIGHT+1)*(i-1), menu_w, TEXT_HEIGHT+2, 0, COLOR_MENU_HIGHLIGHT)
    --                print(opt.text, menu_x+PADDING, menu_y+PADDING+(TEXT_HEIGHT+1)*(i-1), COLOR_MENU_HIGHLIGHT_TEXT)
    --            else
    --                print(opt.text, menu_x+PADDING, menu_y+PADDING+(TEXT_HEIGHT+1)*(i-1), COLOR_MENU_TEXT)
    --            end
    --        end
    --        rrect(menu_x, menu_y, menu_w, menu_h, 1, COLOR_MENU_SECONDARY)
    --    end
    --end

    camera()
end

setmetatable(TacticsMap, { __index = Box})

return TacticsMap