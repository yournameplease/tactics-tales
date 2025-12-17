require("src/tactics/character/object/character")

global record HeadwearSpriteData
	draw_hair: boolean
	draw_beard: boolean
	draw_eyewear: boolean
	sprite: integer
end

global HEADWEAR_SPRITE_DATA <total>: {HeadwearId: HeadwearSpriteData} = {
	hood = {
		draw_hair = false,
		draw_beard = true,
		draw_eyewear = true,
		sprite = 100
	},
	cultist_hood = {
		draw_hair = false,
		draw_beard = false,
		draw_eyewear = false,
		sprite = 98
	},
	wizard_hat = {
		draw_hair = false,
		draw_beard = true,
		draw_eyewear = true,
		sprite = 97
	},
	hooded_wizard_hat = {
		draw_hair = false,
		draw_beard = false,
		draw_eyewear = false,
		sprite = 99
	}
}

