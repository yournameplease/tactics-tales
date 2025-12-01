require("src/character/items/types")
require("src/character/weapons")

local record ItemModule
	interface Item
		get_name: function(self): string
		get_slots: function(self): integer
		get_type: function(self): ItemType

		get_equip_slot: function(self): EquipSlot

		get_weapon_data: function(self): Weapon

		-- get_effects_data(): EquipmentEffects
	end
end

local record ItemImpl
	is ItemModule.Item

	id: ItemId
	name: string
	type: ItemType
	slots: integer

	equip_slot: EquipSlot
	weapon_id: string
end

function ItemModule.new(): ItemModule.Item
	return setmetatable({
		
	}, { __index = ItemImpl })
end

return ItemModule
