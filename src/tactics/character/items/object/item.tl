require("src/tactics/character/items/types")
local wpn = require("src/tactics/character/items/object/weapon")

local record ItemModule
	interface Item
		get_name: function(self): string
		get_slots: function(self): integer
		get_type: function(self): ItemType

		get_equip_slot: function(self): EquipSlot
		get_sprite_data: function(self): ItemSpriteData

		get_weapon_data: function(self): wpn.Weapon

		get_equipment_effects: function(self): { wpn.EquipmentEffect } 
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
	weapon: wpn.Weapon
	equipment_effects: { wpn.EquipmentEffect }
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

function ItemImpl:get_weapon_data(): wpn.Weapon
	return self.weapon
end

function ItemImpl:get_equipment_effects(): { wpn.EquipmentEffect }
	return self.equipment_effects
end

function ItemModule.new(
	id: ItemId,
	name: string,
	item_type: ItemType,
	slots: integer,
	equip_slot: EquipSlot,
	sprite_data: ItemSpriteData,
	equipment_effects: {wpn.EquipmentEffect},
	weapon: wpn.Weapon
): ItemModule.Item
	local item: ItemImpl = {
		id = id,
		name = name,
		type = item_type,
		slots = slots,
		equip_slot = equip_slot,
		sprite_data = sprite_data,
		equipment_effects = equipment_effects, -- note: copied by reference
		weapon = weapon
	}
	return setmetatable(item, { __index = ItemImpl })
end

return ItemModule
