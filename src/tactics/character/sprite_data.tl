require("src/tactics/character/object/character")

-- why so many integer ids?
-- I want all same (all strings or all ints) for easier typing
-- strings are probably better but I don't want to think of a string id
-- for every option.
-- This makes character templates less readable, so may want to go to strings
-- eventuall.

local BODY_CLASS: {integer: string} = {
	[1] = "DEFAULT",
	[2] = "SLEEVELESS",
	[3] = "SHIRTLESS", -- for female, this should convert to sleeveless,
	[4] = "ROBED",
	[5] = "CHILD",
}

local record HeadwearSpriteData
	name: string -- currently unused, more for readability
	draw_hair: boolean
	draw_beard: boolean
	draw_eyewear: boolean
	sprite: integer
end

local HEADWEAR: {integer: HeadwearSpriteData} = {
	[1] = {
		name = 'hood',
		draw_hair = false,
		draw_beard = true,
		draw_eyewear = true,
		sprite = 100
	},
	[2] = {
		name = 'cultist_hood',
		draw_hair = false,
		draw_beard = false,
		draw_eyewear = false,
		sprite = 98
	},
	[3] = {
		name = 'wizard_hat',
		draw_hair = false,
		draw_beard = true,
		draw_eyewear = true,
		sprite = 97
	},
	[4] = {
		name = 'hooded_wizard_hat',
		draw_hair = false,
		draw_beard = false,
		draw_eyewear = false,
		sprite = 99
	},
	[5] = {
		name = 'fancy_hat',
		draw_hair = false,
		draw_beard = true,
		draw_eyewear = true,
		sprite = 101,
	},
	[6] = {
		name = 'animal_mask',
		draw_hair = true,
		draw_beard = true,
		draw_eyewear = false,
		sprite = 103,
	},
}


local sprite_data = {
	HeadwearSpriteData = HeadwearSpriteData,
	BODY_CLASS = BODY_CLASS,
	HEADWEAR = HEADWEAR,
}

return sprite_data
