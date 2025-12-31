require("src/tactics/character/items/object/weapon")
require("src/tactics/character/animation_data")
local animation = require("src/tactics/animation")
local ItemInventory = require("src/tactics/character/items/object/item_inventory")

global enum Side
    "player"
    "enemy"
    "neutral"
end

global enum Sex
    "male"
    "female"
end 

global enum CharacterAppearanceKey
	"head"
	"hair"
	"skin"
	"hair_color"
	"body_class"
	"beard"
	"eyes"
	"eyewear"
	"headwear"
end

global record CharacterAppearance
    sex: Sex
	head: string
    hair: string
    skin: string
    hair_color: string
    body_class: string
    beard: string
    eyes: string
	eyewear: string
	headwear: string
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

global interface DrawableCharacterInstance
	side: Side
	has_acted: boolean -- used for outline color...
	
	animation_data: animation.AnimatedSpriteData
    -- prerendered sprites by animation frame name
    sprites: { AnimationFrameName: Userdata }

	character: Character
end

return Character
