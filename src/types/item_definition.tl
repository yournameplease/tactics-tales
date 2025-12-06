require("src/character/items/types")
require("src/character/items/object/weapon")


global record WeaponDefinition
    name: string
    sprite: integer
    hand_anchor: AnimationAnchorPoint
    damage: integer
    accuracy: integer
    type: WeaponType
    body_type: WeaponBodyType
    min_range: integer
    max_range: integer
end


global record ItemDefinition
	name: string
	type: ItemType
	slots: integer

	-- Equippables
	equip_slot: EquipSlot
	sprite_data: ItemSpriteData
	weapon_definition: WeaponDefinition
	equipment_effects: { EquipmentEffect }

	-- Consumables
	
end
