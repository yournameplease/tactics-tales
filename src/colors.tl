--https://www.lexaloffle.com/bbs/?tid=149249
local record Colors
end

global enum ColorTableId
	"paper"
end

local rows_by_id <total>: {ColorTableId: integer} = {
	["paper"] = 32	
}

local color_table_sprite = 1

function Colors.apply_colortable_row(row_id: ColorTableId)
		local color_row = rows_by_id[row_id]
		local sprite=pt.get_spr(color_table_sprite)
		local address=0x8000+color_row*64
		for x=0,63 do
				local c=sprite:get(x,color_row)
				pt.poke(address+x,c)
		end
		pt.poke(0x550b,0x3f)
end

global enum PaletteId
	"default"
	"paper"
end

local palette_sprite = 2
local cols_by_id <total>: {PaletteId: integer} = {
	["default"] = 0,	
	["paper"] = 1	
}

function Colors.apply_palette(palette_id: PaletteId)
		local color_col = cols_by_id[palette_id]
		local sprite=pt.get_spr(palette_sprite)
		for y=1,63 do
				local c=sprite:get(color_col,y)
				pt.set_pal(y,c)
		end
end


return Colors
