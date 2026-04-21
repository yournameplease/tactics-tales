---@brief
--- Manages a character's inventory.
--- Handles adding, removing, equipping, and unequipping items,
--- enforcing slot and equipment rules.

local wpn = require("src.tactics.character.items.object.weapon")
local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")

---@class EffectDescription
---@field name? string
---@field description string
local EffectDescription = {}

---@class ItemDescription
---@field name string
---@field effects EffectDescription[]
local ItemDescription = {}

---@class InventoryItem
---@field item Item
---@field _current_slot integer Slot index for this item (recalculated on any inventory change).
---@field equip_slot? EquipSlot Equip slot if currently equipped; nil otherwise.
local InventoryItem = {}

---@class ItemInventory
---@field package items InventoryItem[]
---@field package max_slots integer
---@field package _items_by_slot table<integer, InventoryItem> Slot-index-to-InventoryItem map; recalculated after any change.
---@field package _items_by_equip_slot table<EquipSlot, InventoryItem> Equip-slot-to-InventoryItem map; recalculated after any change.
---@field package _current_slot_usage integer Total slots consumed by current items; recalculated after any change.
local ItemInventory = {}
ItemInventory.__index = ItemInventory

--- Recalculate slot indices, equip-slot maps, and total slot usage.
function ItemInventory:compute_current_slots()
    self._items_by_slot = {}
    self._items_by_equip_slot = {}
    local count = 1
    for _, inv_item in ipairs(self.items) do
        inv_item._current_slot = count
        self._items_by_slot[count] = inv_item
        if inv_item.equip_slot ~= nil then
            self._items_by_equip_slot[inv_item.equip_slot] = inv_item
        end
        count = count + inv_item.item.slots
    end
    self._current_slot_usage = count
end

--- Return all items in the inventory as an array.
---@return Item[]
function ItemInventory:get_items()
    return lists.do_map(
        self.items,
        function(i)
            return i.item
        end
    )
end

--- Return a map of slot index to item.
---@return table<integer, Item>
function ItemInventory:get_items_by_slot()
    ---@diagnostic disable-next-line
    return maps.map(
        ---@param _ integer
        ---@param i InventoryItem
        ---@return Item
        function(_, i)
            return i.item
        end
    )(self._items_by_slot)
end

--- Return the total inventory capacity.
---@return integer
function ItemInventory:get_max_slots()
    return self.max_slots
end

--- Return a map of equip slot to equipped item.
---@return table<EquipSlot, Item>
function ItemInventory:get_equipped_items()
    ---@diagnostic disable-next-line
    return maps.map(
        ---@param _ EquipSlot
        ---@param i InventoryItem
        ---@return Item
        function(_, i)
            return i.item
        end
    )(self._items_by_equip_slot)
end

--- Return all equipped weapon objects (from TWO_HANDS, MAIN_HAND, and OFF_HAND slots).
---@return Weapon[]
function ItemInventory:get_equipped_weapons()
    local out = {}
    if self._items_by_equip_slot["TWO_HANDS"] ~= nil
        and self._items_by_equip_slot["TWO_HANDS"].item.type == "WEAPON" then
        table.insert(out, self._items_by_equip_slot["TWO_HANDS"].item.weapon)
    end
    if self._items_by_equip_slot["MAIN_HAND"] ~= nil
        and self._items_by_equip_slot["MAIN_HAND"].item.type == "WEAPON" then
        table.insert(out, self._items_by_equip_slot["MAIN_HAND"].item.weapon)
    end
    if self._items_by_equip_slot["OFF_HAND"] ~= nil
        and self._items_by_equip_slot["OFF_HAND"].item.type == "WEAPON" then
        table.insert(out, self._items_by_equip_slot["OFF_HAND"].item.weapon)
    end
    return out
end

--- Return whether the item at index can be equipped without slot conflicts.
---@param index integer
---@return boolean
function ItemInventory:can_equip(index)
    local equip_slot = self.items[index].item.equip_slot
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

--- Return whether the item at index is currently equipped.
---@param index integer
---@return boolean
function ItemInventory:is_equipped(index)
    return self.items[index].equip_slot ~= nil
end

--- Return whether the given item can be added without exceeding capacity.
---@param item Item
---@return boolean
function ItemInventory:can_add_item(item)
    return self._current_slot_usage + item.slots <= self.max_slots
end

--- Add an item to the inventory. Asserts that the item fits.
---@param item Item
function ItemInventory:add_item(item)
    assert(self:can_add_item(item))
    table.insert(self.items, {item = item})
    self:compute_current_slots()
end

--- Equip the item at index, unequipping any conflicting items first.
---@param index integer
function ItemInventory:equip_item(index)
    local inventory_item = self.items[index]

    local slot_to_equip = inventory_item.item.equip_slot
    assert(slot_to_equip ~= "NONE")
    assert(slot_to_equip ~= "ANY_HAND", "NOT IMPLEMENTED")

    local slots_to_unequip
    if slot_to_equip == "MAIN_HAND" then
        slots_to_unequip = {"MAIN_HAND", "TWO_HANDS"}
    elseif slot_to_equip == "OFF_HAND" then
        slots_to_unequip = {"OFF_HAND", "TWO_HANDS"}
    elseif slot_to_equip == "TWO_HANDS" then
        slots_to_unequip = {"MAIN_HAND", "OFF_HAND", "TWO_HANDS"}
    elseif slot_to_equip == "BODY" then
        slots_to_unequip = {}
    else
        error("unexpected equip slot: " .. tostring(slot_to_equip))
    end

    for _, s in ipairs(slots_to_unequip) do
        self:unequip_item_in_equip_slot(s)
    end

    inventory_item.equip_slot = slot_to_equip
    self._items_by_equip_slot[slot_to_equip] = inventory_item
end

--- Unequip whatever item occupies the given equip slot, if any.
---@param slot EquipSlot
function ItemInventory:unequip_item_in_equip_slot(slot)
    if self._items_by_equip_slot[slot] ~= nil then
        self._items_by_equip_slot[slot].equip_slot = nil
        self._items_by_equip_slot[slot] = nil
    end
end

--- Unequip the item at index.
---@param index integer
function ItemInventory:unequip_item(index)
    local equip_slot = self.items[index].equip_slot
    if equip_slot ~= nil then
        self:unequip_item_in_equip_slot(equip_slot)
    end
end

--- Remove the item at slot index from the inventory.
---@param slot integer
function ItemInventory:remove_item(slot)
    local inv_item = self._items_by_slot[slot]
    del(self.items, inv_item)
    self:compute_current_slots()
end

--- Move an item to a new position (not yet implemented).
---@param _index integer
---@param _before_index integer
function ItemInventory:move_item(_index, _before_index)
    error("not implemented")

    self:compute_current_slots() -- luacheck: ignore (unreachable after error)
end

--- Return player-facing names and effect descriptions for all equipped items.
---@return ItemDescription[]
function ItemInventory:get_item_descriptions()
    local out = {}

    local equipped = self:get_equipped_items()
    for _, item in pairs(equipped) do
        local description = {
            name = item.name,
            effects = {},
        }
        if item.weapon and item.weapon.effects then
            local effects = item.weapon.effects
            for _, eff in ipairs(effects) do
                table.insert(description.effects, {
                    name        = wpn.effect.effect_name[eff.type],
                    description = wpn.effect.effect_description[eff.type],
                })
            end
        end
        if item.equipment_effects then
            local effects = item.equipment_effects
            for _, eff in ipairs(effects) do
                table.insert(description.effects, {
                    name        = nil,
                    description = wpn.effect.equipment_effect_description(eff),
                })
            end
        end

        table.insert(out, description)
    end
    return out
end

--- Create a new empty inventory with the given maximum slot count.
---@param max_slots integer
---@return ItemInventory
local function new(max_slots)
    ---@type ItemInventory
    local inventory = setmetatable({}, ItemInventory)
    inventory.max_slots = max_slots
    inventory.items = {}
    inventory:compute_current_slots()
    return inventory
end

return {
    ItemInventory = ItemInventory,
    new = new,
}
