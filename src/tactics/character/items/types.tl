local point = require("src/tactics/util/point")
local Point = point.Point

local type ItemId = string

local enum ItemType
	"WEAPON"
	"ARMOR"
	"SHIELD"
	"CONSUMABLE"
	"MISC"
end

local enum EquipSlot
	"MAIN_HAND"
	"OFF_HAND"
	"TWO_HANDS"
	"ANY_HAND"
	"BODY"
	"NONE"
end

local record ItemSpriteData
	sprite: integer
	anchor: Point
end

local item_types = {
	ItemId = ItemId,
	ItemType = ItemType,
	EquipSlot = EquipSlot,
	ItemSpriteData = ItemSpriteData,
}

return item_types
