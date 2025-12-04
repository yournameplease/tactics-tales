require("src/types")
require("src/character/items/object/weapon")
local ItemInventory = require("src/character/items/object/item_inventory")

local SKIN_COLORS: { { Color, Color } } = {
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
	"glasses"
	"hood"
	"wizard_hat"
	"hooded_wizard_hat"
end

global enum BodyClass
	"CHILD"
	"DEFAULT"
	"SLEEVELESS"
	"SHIRTLESS" -- for female, this will convert to sleeveless
	"ROBED"
end

global record CharacterAppearance
    sex: Sex
    hair: integer
    skin: integer
    hair_color: Color
    body_class: BodyClass
    beard: integer
    -- beard_color: Color
    eyes: integer
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

return Character
