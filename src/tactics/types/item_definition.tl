require("src/tactics/character/items/types")
local wpn = require("src/tactics/character/items/object/weapon")


global record WeaponDefinition
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


global record ItemDefinition
	name: string
	type: ItemType
	slots: integer

	-- Equippables
	equip_slot: EquipSlot
	sprite_data: ItemSpriteData
	weapon_definition: WeaponDefinition
	equipment_effects: { wpn.EquipmentEffect }

	-- Consumables
	
end
