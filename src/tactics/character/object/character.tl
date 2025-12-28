require("src/tactics/types")
require("src/tactics/character/items/object/weapon")
local ItemInventory = require("src/tactics/character/items/object/item_inventory")

global SKIN_COLORS: { { Color, Color } } = {
    {15, 31},
    {31, 4},
    {4, 20},
    {20, 21}
}

global enum Sex
    "male"
    "female"
end 

global enum HeadwearId
	"hood"
	"cultist_hood"
	"wizard_hat"
	"hooded_wizard_hat"
	"fancy_hat"
	"animal_mask"
end

global enum BodyClass
	"CHILD"
	"DEFAULT"
	"SLEEVELESS"
	"SHIRTLESS" -- for female, this will convert to sleeveless
	"ROBED"
end

global CHARACTER_CUSTOMIZATION_OPTIONS = {
	HEAD = {
		key = "head",
		options = {
			{text = "A" , value = 64},
			{text = "B" , value = 68},
		},
	},
	HAIR = {
		key = "hair",
		options = {
			{text = "A" , value = 72},
			{text = "B" , value = 73},
			{text = "C" , value = 74},
			{text = "D" , value = 75},
			{text = "E" , value = 77},
			{text = "F" , value = 80},
			{text = "G" , value = 81},
			{text = "H" , value = 82},
			{text = "I" , value = 83},
			{text = "J" , value = 85},
			{text = "K" , value = 80},
		},
	},
	SKIN = {
		key = "skin",
		options = {
			{text = "A" , value = 1},
			{text = "B" , value = 2},
			{text = "C" , value = 3},
			{text = "D" , value = 4},
		},
	},
	HAIR_COLOR = {
		key = "hair_color",
		options = {
			{text = "4" , value = 4},
			{text = "5" , value = 5},
			{text = "6" , value = 6},
			{text = "9" , value = 9},
			{text = "10" , value = 10},
			{text = "20" , value = 20},
			{text = "21" , value = 21},
			{text = "22" , value = 22},
			{text = "24" , value = 24},
			{text = "25" , value = 25},
			{text = "31" , value = 31},
		},
	},
	BODY_CLASS = {
		key = "body_class",
		options = {
			{text = "Default" , value = "DEFALUT"},
			{text = "Sleeveless" , value = "SLEEVELESS"},
			{text = "Shirtless" , value = "SHIRTLESS"},
			{text = "Robe" , value = "ROBED"},
		},
	},
	BEARD = {
		key = "beard",
		options = {
			{text = "None" , value = nil},
			{text = "Unshaven" , value = 89},
			{text = "Mustache" , value = 90},
			{text = "Sideburns" , value = 91},
			{text = "Beard" , value = 92},
			{text = "Goatee" , value = 93},
			{text = "Bushy Beard" , value = 94},
		},
	},
	EYES = {
		key = "eyes",
		options = {
			{text = "A" , value = 120},
		},
	},
	EYEWEAR = {
		key = "eyewear",
		options = {
			{text = "None" , value = nil},
			{text = "Glasses" , value = 96},
			{text = "Mask" , value = 102},
		},
	},
	HEADWEAR = {
		key = "headwear",
		options = {
			{text = "None" , value = nil},
			{text = "Wizard Hat" , value = "wizard_hat"},
			{text = "Hood" , value = "hood"},
			{text = "Covered Hood" , value = "cultist_hood"},
			{text = "Hooded Wizard Hat" , value = "hooded_wizard_hat"},
			{text = "Hat" , value = "fancy_hat"},
			{text = "Animal Mask" , value = "animal_mask"},
		},
	},
}


global record CharacterAppearance
    sex: Sex
	head: integer
    hair: integer
    skin: integer
    hair_color: Color
    body_class: BodyClass
    beard: integer
    -- beard_color: Color
    eyes: integer
	eyewear: integer
	headwear: HeadwearId
end

global record CharacterStats
    hp_max: integer
    movement: integer
    def: integer
end

global record Character
    id: integer
    name: string
    appearance: CharacterAppearance
    stats: CharacterStats
	inventory: ItemInventory.ItemInventory
end

function Character:get_weapon_range(): integer, integer
	local weapons = self.inventory:get_equipped_weapons()

	if #weapons == 0 then
		return 0,0
	end

	-- TODO: dual weilding
	return weapons[1].min_range, weapons[1].max_range
end

return Character
