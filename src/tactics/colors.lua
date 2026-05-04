---@brief
--- Provides color-related utilities, including palettes and functions
--- to apply them.

--https://www.lexaloffle.com/bbs/?tid=149249

---@alias Color integer

---@alias ColorTableId
---| "light"
---| "dark"

---@alias PaletteId "default"|"paper"

---@type integer[][] Each entry is a {light, dark} pair, red-violet + pink.
local RAINBOW = {
    {8, 24},
    {9, 25},
    {10, 31},
    {11, 27},
    {28, 12},
    {16, 1},
    {29, 18},
    {14, 30},
}

local colors = {}

--- Return the rainbow color row at position `i`, wrapping around the table.
---@param i integer 0-based index into the rainbow cycle.
---@return integer[] Pair of {light, dark}.
function colors.rainbow(i)
    return RAINBOW[i % #RAINBOW + 1]
end

---@type table<ColorTableId, integer>
local rows_by_id = {
    ["light"] = 33,
    ["dark"] = 35,
}

local color_table_sprite = 1

--- Load a color table row from a sprite and apply it to the hardware palette registers.
---@param row_id ColorTableId Identifies which color table row to apply.
function colors.apply_colortable_row(row_id)
    local color_row = rows_by_id[row_id]
    local sprite = get_spr(color_table_sprite)
    local address = 0x8000 + color_row * 64
    for x = 0, 63 do
        local c = sprite:get(x, color_row)
        poke(address + x, c)
    end
    poke(0x550b, 0x3f)
end

local palette_sprite = 2

---@type table<PaletteId, integer>
local cols_by_id = {
    ["default"] = 0,
    ["paper"]   = 1,
}

--- Load a palette column from a sprite and apply it via pal.
---@param palette_id PaletteId Identifies which palette column to apply.
function colors.apply_palette(palette_id)
    local color_col = cols_by_id[palette_id]
    local sprite = get_spr(palette_sprite)
    for y = 1, 63 do
        local c = sprite:get(color_col, y)
        pal(y, c)
    end
end

return colors
