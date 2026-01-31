local point = require("src.tactics.util.point")
local Point = point.Point
local item_types = require("src.tactics.character.items.types")
local wpn = require("src.tactics.character.items.object.weapon")

local record WeaponDefinition
    name: string
    sprite: integer
    hand_anchor: Point
    damage: integer
    accuracy: integer
    type: wpn.WeaponType
    body_type: wpn.WeaponBodyType
    min_range: integer
    max_range: integer
	effects: {wpn.WeaponEffect}
end

local record ItemDefinition
	name: string
	type: item_types.ItemType
	slots: integer

	-- Equippables
	equip_slot: item_types.EquipSlot
	sprite_data: item_types.ItemSpriteData
	weapon_definition: WeaponDefinition
	equipment_effects: { wpn.EquipmentEffect }
	appearance_overrides: any --CharacterAppearance

	-- Consumables
	
end

local item_definition = {
	ItemDefinition = ItemDefinition,
	WeaponDefinition = WeaponDefinition,
}

return item_definition
