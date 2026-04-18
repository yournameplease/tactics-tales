---@brief
--- Defines the data structure for item definitions, which are
--- used by the item generator.

---@class WeaponDefinition
---@field name string
---@field sprite integer
---@field hand_anchor Point Sprite-space anchor point for the weapon hand.
---@field damage integer
---@field accuracy integer
---@field type WeaponType
---@field body_type WeaponBodyType Determines which body sprite variant is shown when equipped.
---@field min_range integer Minimum attack range in tiles.
---@field max_range integer Maximum attack range in tiles.
---@field effects WeaponEffect[] Combat properties granted by this weapon.
local WeaponDefinition = {}

---@class ItemDefinition
---@field name string
---@field type ItemType
---@field slots integer Number of inventory slots this item occupies.
---@field equip_slot EquipSlot Slot this item occupies when equipped.
---@field sprite_data ItemSpriteData Visual data used when rendering the item.
---@field weapon_definition WeaponDefinition|nil Weapon stats; present only for weapon-type items.
---@field equipment_effects EquipmentEffect[] Effects granted when this item is equipped.
---@field appearance_overrides CharacterAppearance
local ItemDefinition = {}

local item_definition = {
    ItemDefinition = ItemDefinition,
    WeaponDefinition = WeaponDefinition,
}

return item_definition
