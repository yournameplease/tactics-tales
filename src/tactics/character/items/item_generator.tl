local Item = require("src.tactics.character.items.object.item")
local wpn = require("src.tactics.character.items.object.weapon")
local item_definition = require("src.tactics.types.item_definition")

local item_generator = {}

local function generate_weapon(def: item_definition.WeaponDefinition): wpn.Weapon
	if def == nil then
		return nil
	end
	-- may need to copy data in the future
	return setmetatable({},{ __index = def})
end

function item_generator.generate(
	item_id: string,
	item_data: {string: item_definition.ItemDefinition}
): Item.Item
	local data = item_data[item_id]
	assert(data ~= nil)
	
	return Item.new(
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
