---@brief
--- Contains basic, shared type definitions related to items,
--- such as item IDs, types, and equipment slots.

---@alias ItemId string

---@alias ItemType "WEAPON"|"ARMOR"|"SHIELD"|"CONSUMABLE"|"MISC"

---@alias EquipSlot "MAIN_HAND"|"OFF_HAND"|"TWO_HANDS"|"ANY_HAND"|"BODY"|"NONE"

---@class ItemSpriteData
---@field sprite integer Sprite index used to render the item.
---@field anchor PointRecord Sprite-space anchor point for positioning the item visually.

return {
}
