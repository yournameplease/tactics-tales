require("src/tactics/types")

local record ItemTypes
end

global type ItemId = string

global enum ItemType
	"WEAPON"
	"ARMOR"
	"SHIELD"
	"CONSUMABLE"
	"MISC"
end

global enum EquipSlot
	"MAIN_HAND"
	"OFF_HAND"
	"TWO_HANDS"
	"ANY_HAND"
	"BODY"
	"NONE"
end

global record ItemSpriteData
	sprite: integer
	anchor: Point
end

return ItemTypes
