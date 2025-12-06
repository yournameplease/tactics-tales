require("src/character/items/types")
require("src/character/items/object/weapon")

local record ItemModule
	interface Item
		get_name: function(self): string
		get_slots: function(self): integer
		get_type: function(self): ItemType

		get_equip_slot: function(self): EquipSlot
		get_sprite_data: function(self): ItemSpriteData

		get_weapon_data: function(self): Weapon

		get_equipment_effects: function(self): { EquipmentEffect } 
	end
end

local record ItemImpl
	is ItemModule.Item

	id: ItemId
	name: string
	type: ItemType
	slots: integer

	equip_slot: EquipSlot
	sprite_data: ItemSpriteData
	weapon: Weapon
	equipment_effects: { EquipmentEffect }
end


function ItemImpl:get_name(): string
	return self.name
end

function ItemImpl:get_slots(): integer
	return self.slots
end

function ItemImpl:get_type(): ItemType
	return self.type
end

function ItemImpl:get_equip_slot(): EquipSlot
	return self.equip_slot
end

function ItemImpl:get_sprite_data(): ItemSpriteData
	return self.sprite_data
end

function ItemImpl:get_weapon_data(): Weapon
	return self.weapon
end

function ItemImpl:get_equipment_effects(): { EquipmentEffect }
	return self.equipment_effects
end

function ItemModule.new(
	id: ItemId,
	name: string,
	type: ItemType,
	slots: integer,
	equip_slot: EquipSlot,
	sprite_data: ItemSpriteData,
	weapon: Weapon
): ItemModule.Item
	local item: ItemImpl = {
		id = id,
		name = name,
		type = type,
		slots = slots,
		equip_slot = equip_slot,
		sprite_data = sprite_data,
		weapon = weapon
	}
	return setmetatable(item, { __index = ItemImpl })
end

return ItemModule
