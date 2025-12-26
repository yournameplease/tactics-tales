require("src/tactics/types")

--https://www.lexaloffle.com/bbs/?tid=149249

local RAINBOW: {{Color, Color}} = {
	{8, 24},
	{9, 25},
	{10, 31},
	{11, 27},
	{28, 12},
	{16, 1},
	{29, 18},
	{14, 30},
}

local enum ColorTableId
	"paper"
end

local enum PaletteId
	"default"
	"paper"
end

local colors = {
	ColorTableId = ColorTableId,
	PaletteId = PaletteId,
}

function colors.rainbow(i: integer): {Color, Color}
	return RAINBOW[i%#RAINBOW+1]
end

local rows_by_id <total>: {ColorTableId: integer} = {
	["paper"] = 32	
}

local color_table_sprite = 1

function colors.apply_colortable_row(row_id: ColorTableId)
		local color_row = rows_by_id[row_id]
		local sprite=pt.get_spr(color_table_sprite)
		local address=0x8000+color_row*64
		for x=0,63 do
				local c=sprite:get(x,color_row)
				pt.poke(address+x,c)
		end
		pt.poke(0x550b,0x3f)
end

local palette_sprite = 2
local cols_by_id <total>: {PaletteId: integer} = {
	["default"] = 0,	
	["paper"] = 1	
}

function colors.apply_palette(palette_id: PaletteId)
		local color_col = cols_by_id[palette_id]
		local sprite=pt.get_spr(palette_sprite)
		for y=1,63 do
				local c=sprite:get(color_col,y)
				pt.set_pal(y,c)
		end
end


return colors
