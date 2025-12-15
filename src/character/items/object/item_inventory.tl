local Item = require("src/character/items/object/item")
require("src/character/items/types")
require("src/character/items/object/weapon")
local List = require("src/util/list")
require("src/util")

local interface ItemInventory

	-- items will be indexed, to account for slots
	get_items: function(self): { Item.Item }
	get_items_by_slot: function(self): { integer: Item.Item }
	get_max_slots: function(self): integer
	get_equipped_items: function(self): { EquipSlot: Item.Item }
	get_equipped_weapons: function(self): { Weapon }

	can_equip: function(self, index: integer): boolean
	is_equipped: function(self, index: integer): boolean
	can_add_item: function(self, item: Item.Item): boolean
	add_item: function(self, item: Item.Item)
	equip_item: function(self, index: integer)
	unequip_item: function(self, index: integer)
	unequip_item_in_equip_slot: function(self, slot: EquipSlot)
	remove_item: function(self, index: integer)
	move_item: function(self, index: integer, before_index: integer)
end

local record InventoryItem
	item: Item.Item
	-- recalculate this when updated 
	_current_slot: integer
	equip_slot: EquipSlot
end
	


local record ItemInventoryImpl
	is ItemInventory

	items: { InventoryItem }
	max_slots: integer

	-- recalculate after updates
	_items_by_slot: { integer: InventoryItem }
	_items_by_equip_slot: { EquipSlot: InventoryItem }
	_current_slot_usage: integer
end

function ItemInventoryImpl:compute_current_slots()
	self._items_by_slot = {}
	self._items_by_equip_slot = {}
	local count = 1
	for _,item in ipairs(self.items) do
		item._current_slot = count
		self._items_by_slot[count] = item
		if (item.equip_slot) ~= nil then
			self._items_by_equip_slot[item.equip_slot] = item
		end
		count = count + item.item:get_slots()
	end
	self._current_slot_usage = count
end

function ItemInventoryImpl:get_items(): { Item.Item }
	return List.do_map(
		self.items,
		function(i: InventoryItem): Item.Item
			return i.item
		end
	)
end

function ItemInventoryImpl:get_items_by_slot(): { integer: Item.Item }
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

function ItemInventoryImpl:get_equipped_weapons(): { Weapon }
	local out: { Weapon } = {}
	if self._items_by_equip_slot["TWO_HANDS"] ~= nil
		and self._items_by_equip_slot["TWO_HANDS"].item:get_type() == "WEAPON" then
		pt.add(out, self._items_by_equip_slot["TWO_HANDS"].item:get_weapon_data())
	end
	if self._items_by_equip_slot["MAIN_HAND"] ~= nil
		and self._items_by_equip_slot["MAIN_HAND"].item:get_type() == "WEAPON" then
		pt.add(out, self._items_by_equip_slot["MAIN_HAND"].item:get_weapon_data())
	end
	if self._items_by_equip_slot["OFF_HAND"] ~= nil
		and self._items_by_equip_slot["OFF_HAND"].item:get_type() == "WEAPON" then
		pt.add(out, self._items_by_equip_slot["OFF_HAND"].item:get_weapon_data())
	end
	return out
end

function ItemInventoryImpl:can_equip(index: integer): boolean
	local equip_slot = self.items[index].item:get_equip_slot()
	if equip_slot == "TWO_HANDS" then
		return self._items_by_equip_slot.MAIN_HAND == nil
			and self._items_by_equip_slot.OFF_HAND == nil
			and self._items_by_equip_slot.TWO_HANDS == nil
	elseif equip_slot == "MAIN_HAND" then
		return self._items_by_equip_slot.MAIN_HAND == nil
			and self._items_by_equip_slot.TWO_HANDS == nil
	elseif equip_slot == "OFF_HAND" then
		return self._items_by_equip_slot.OFF_HAND == nil
			and self._items_by_equip_slot.TWO_HANDS == nil
	elseif equip_slot == "BODY" then
		return self._items_by_equip_slot.BODY == nil
	end
	return false
end

function ItemInventoryImpl:is_equipped(index: integer): boolean
	return self.items[index].equip_slot ~= nil
end

function ItemInventoryImpl:can_add_item(item: Item.Item): boolean
	return self._current_slot_usage + item:get_slots() <= self.max_slots	
end		

function ItemInventoryImpl:add_item(item: Item.Item)
	assert(self:can_add_item(item))
	pt.add(self.items, { item = item })
	self:compute_current_slots()
end

function ItemInventoryImpl:equip_item(index: integer)
	local inventory_item = self.items[index]

	local slot_to_equip = inventory_item.item:get_equip_slot()
	assert(slot_to_equip ~= "NONE")
	assert(slot_to_equip ~= "ANY_HAND", "NOT IMPLEMENTED")

	local slots_to_unequip: {EquipSlot}
	if slot_to_equip == "MAIN_HAND" then
		slots_to_unequip = {"MAIN_HAND", "TWO_HANDS"}
	elseif slot_to_equip == "OFF_HAND" then
		slots_to_unequip = {"OFF_HAND", "TWO_HANDS"}
	elseif slot_to_equip == "TWO_HANDS" then
		slots_to_unequip = {"MAIN_HAND", "OFF_HAND", "TWO_HANDS"}
	elseif slot_to_equip == "BODY" then
		slots_to_unequip = {"MAIN_HAND", "TWO_HANDS"}
	else
		error()
	end
	--unequip

	for _,s in ipairs(slots_to_unequip) do
		self:unequip_item_in_equip_slot(s)
	end

	inventory_item.equip_slot = slot_to_equip
	self._items_by_equip_slot[slot_to_equip] = inventory_item
end

function ItemInventoryImpl:unequip_item_in_equip_slot(slot: EquipSlot)
	if (self._items_by_equip_slot[slot] ~= nil) then
		self._items_by_equip_slot[slot].equip_slot = nil
		self._items_by_equip_slot[slot] = nil
	end
end

function ItemInventoryImpl:unequip_item(index: integer)
	local equip_slot = self.items[index].equip_slot
	self:unequip_item_in_equip_slot(equip_slot)
end

function ItemInventoryImpl:remove_item(slot: integer)
	local item = self._items_by_slot[slot]
	pt.del(self.items, item)
	self:compute_current_slots()
end

function ItemInventoryImpl:move_item(index: integer, before_index: integer)
	error("not implemented")
	
	self:compute_current_slots()
end

local function new(max_slots: integer): ItemInventory
	local inventory: ItemInventoryImpl = {
		max_slots = max_slots,
		items = {}
	}
	setmetatable(inventory, { __index = ItemInventoryImpl })
	inventory:compute_current_slots()
	return inventory
end

return {
	ItemInventory = ItemInventory,
	new = new
}
