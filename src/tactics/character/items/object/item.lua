---@brief
--- Defines the core Item object, representing an individual item in the game.
--- Provides a common interface for all items, such as weapons and armor.


---@class Item
---@field id ItemId
---@field name string
---@field type ItemType
---@field slots integer Number of inventory slots this item occupies.
---@field equip_slot EquipSlot Slot this item occupies when equipped.
---@field sprite_data ItemSpriteData Visual data used when rendering the item.
---@field weapon? Weapon Weapon stats; present only for weapon-type items.
---@field equipment_effects EquipmentEffect[] Passive bonuses granted when this item is equipped.
---@field appearance_overrides any

---@class ItemImpl : Item
local ItemImpl = {}
ItemImpl.__index = ItemImpl

local item = {
}

--- Create a new Item instance.
---@param id ItemId
---@param name string
---@param item_type ItemType
---@param slots integer
---@param equip_slot EquipSlot
---@param sprite_data ItemSpriteData
---@param equipment_effects EquipmentEffect[]
---@param appearance_overrides any
---@param weapon Weapon?
---@return Item
function item.new(id, name, item_type, slots, equip_slot, sprite_data, equipment_effects, appearance_overrides, weapon)
    ---@type Item
    local self = setmetatable({}, ItemImpl)
    self.id = id
    self.name = name
    self.type = item_type
    self.slots = slots
    self.equip_slot = equip_slot
    self.sprite_data = sprite_data
    self.equipment_effects = equipment_effects -- note: copied by reference
    self.appearance_overrides = appearance_overrides -- note: copied by reference
    self.weapon = weapon
    return self
end

return item
