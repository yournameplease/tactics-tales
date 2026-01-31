local item_types = require("src.tactics.character.items.types")
local wpn = require("src.tactics.character.items.object.weapon")

local interface Item
	-- getters are not needed, just interface the field
	get_name: function(self): string
	get_slots: function(self): integer
	get_type: function(self): item_types.ItemType

	get_equip_slot: function(self): item_types.EquipSlot
	get_sprite_data: function(self): item_types.ItemSpriteData

	get_weapon_data: function(self): wpn.Weapon

	get_equipment_effects: function(self): { wpn.EquipmentEffect } 
	appearance_overrides: any
end

local item = {
	Item = Item,
}

local record ItemImpl
	is Item

	id: item_types.ItemId
	name: string
	type: item_types.ItemType
	slots: integer

	equip_slot: item_types.EquipSlot
	sprite_data: item_types.ItemSpriteData
	weapon: wpn.Weapon
	equipment_effects: { wpn.EquipmentEffect }
	appearance_overrides: any
end


function ItemImpl:get_name(): string
	return self.name
end

function ItemImpl:get_slots(): integer
	return self.slots
end

function ItemImpl:get_type(): item_types.ItemType
	return self.type
end

function ItemImpl:get_equip_slot(): item_types.EquipSlot
	return self.equip_slot
end

function ItemImpl:get_sprite_data(): item_types.ItemSpriteData
	return self.sprite_data
end

function ItemImpl:get_weapon_data(): wpn.Weapon
	return self.weapon
end

function ItemImpl:get_equipment_effects(): { wpn.EquipmentEffect }
	return self.equipment_effects
end

function item.new(
	id: item_types.ItemId,
	name: string,
	item_type: item_types.ItemType,
	slots: integer,
	equip_slot: item_types.EquipSlot,
	sprite_data: item_types.ItemSpriteData,
	equipment_effects: {wpn.EquipmentEffect},
	appearance_overrides: any,
	weapon: wpn.Weapon
): Item
	local self: ItemImpl = {
		id = id,
		name = name,
		type = item_type,
		slots = slots,
		equip_slot = equip_slot,
		sprite_data = sprite_data,
		equipment_effects = equipment_effects, -- note: copied by reference
		appearance_overrides = appearance_overrides, -- note: copied by reference
		weapon = weapon
	}
	return setmetatable(self, { __index = ItemImpl })
end

return item
