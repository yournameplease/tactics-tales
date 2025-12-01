local Item = require("src/character/items/object/item")
require("src/character/items/types")
require("src/character/weapons")
local List = require("src/util/list")
require("src/util")

local record ItemInventoryModule
	interface ItemInventory

		-- items will be indexed, to account for slots
		get_items: function(self): { integer: Item.Item }
		get_max_slots: function(self): integer
		get_equipped_items: function(self): { EquipSlot: Item.Item }

		can_add_item: function(self, item: Item.Item): boolean
		add_item: function(self, item: Item.Item)
		equip_item: function(self, slot: integer)
		unequip_item: function(self, slot: integer)
		unequip_item_in_equip_slot: function(self, slot: EquipSlot)
		remove_item: function(self, slot: integer)
		move_item: function(self, slot: integer, before_slot: integer)
	end
end

local record InventoryItem
	item: Item.Item
	-- recalculate this when updated 
	_current_slot: integer
	equip_slot: EquipSlot
end
	


local record ItemInventoryImpl
	is ItemInventoryModule.ItemInventory

	items: { InventoryItem }
	max_slots: integer

	-- recalculate after updates
	_items_by_slot: { integer: InventoryItem }
	_items_by_equip_slot: { EquipSlot: InventoryItem }
	_current_slot_usage: integer
end

function ItemInventoryImpl:compute_current_slots(items: {InventoryItem})
	self._items_by_slot = {}
	local count = 1
	for _,item in ipairs(items) do
		item._current_slot = count
		self._items_by_slot[count] = item
		if (item.equip_slot) ~= nil then
			self._items_by_equip_slot[item.equip_slot] = item
		end
		count = count + item.item:get_slots()
	end
	self._current_slot_usage = count
end

function ItemInventoryImpl:get_items(): { integer: Item.Item }
	return tmap(
		self._items_by_slot,
		function(i: InventoryItem): Item.Item
			return i.item
		end
	)
end

function ItemInventoryImpl:get_max_slots(): integer
	return self.max_slots
end

function ItemInventoryImpl:get_equipped_items(): { EquipSlot: Item.Item }
	return tmap(
		self._items_by_equip_slot,
		function(i: InventoryItem): Item.Item
			return i.item
		end
	)
end

function ItemInventoryImpl:can_add_item(item: Item.Item): boolean
	return self._current_slot_usage + item:get_slots() <= self.max_slots	
end		

function ItemInventoryImpl:add_item(item: Item.Item)
	assert(self:can_add_item(item))
	add(self.items, { item = item })
	self:compute_current_slots(self.items)
end

function ItemInventoryImpl:equip_item(slot: integer)
	local inventory_item = self._items_by_slot[slot]

	local equip_slot = inventory_item.equip_slot
	assert(equip_slot ~= "NONE")
	assert(equip_slot ~= "ANY_HAND", "NOT IMPLEMENTED")

	local slots_to_unequip: {EquipSlot}
	if equip_slot == "MAIN_HAND" then
		slots_to_unequip = {"MAIN_HAND", "TWO_HANDS"}
	elseif equip_slot == "OFF_HAND" then
		slots_to_unequip = {"OFF_HAND", "TWO_HANDS"}
	elseif equip_slot == "TWO_HANDS" then
		slots_to_unequip = {"MAIN_HAND", "OFF_HAND", "TWO_HANDS"}
	elseif equip_slot == "BODY" then
		slots_to_unequip = {"MAIN_HAND", "TWO_HANDS"}
	else
		error()
	end
	--unequip

	for _,s in ipairs(slots_to_unequip) do
		self:unequip_item_in_equip_slot(s)
	end

	inventory_item.equip_slot = equip_slot
	self._items_by_equip_slot[equip_slot] = inventory_item
end

function ItemInventoryImpl:unequip_item_in_equip_slot(slot: EquipSlot)
	self._items_by_equip_slot[slot].equip_slot = nil
	self._items_by_equip_slot[slot] = nil
end

function ItemInventoryImpl:unequip_item(slot: integer)
	local equip_slot = self._items_by_slot[slot].equip_slot
	self:unequip_item_in_equip_slot(equip_slot)
end

function ItemInventoryImpl:remove_item(slot: integer)
	local item = self._items_by_slot[slot]
	del(self.items, item) 	
	self:compute_current_slots(self.items)
end

function ItemInventoryImpl:move_item(slot: integer, before_slot: integer)
	error("not implemented")
	
	self:compute_current_slots(self.items)
end



return ItemInventoryModule
