---@brief
--- A factory for creating item instances from item definitions.

local item_mod = require("src.tactics.character.items.object.item")

local item_generator = {}

--- Create a Weapon from a WeaponDefinition by inheriting its fields via metatable.
---@param def WeaponDefinition?
---@return Weapon?
local function generate_weapon(def)
    if def == nil then
        return nil
    end
    -- may need to copy data in the future
    return setmetatable({}, { __index = def }) --[[@as Weapon]]
end

--- Create an Item instance from the items table using the given item ID.
---@param item_id string
---@param item_data table<string, ItemDefinition>
---@return Item
function item_generator.generate(item_id, item_data)
    local data = item_data[item_id]
    assert(data ~= nil)

    return item_mod.new(
        item_id,
        data.name,
        data.type,
        data.slots,
        data.equip_slot,
        data.sprite_data,
        data.equipment_effects,
        data.appearance_overrides,
        generate_weapon(data.weapon_definition)
    )
end

return item_generator
