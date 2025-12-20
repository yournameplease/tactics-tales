local Item = require("src/tactics/character/items/object/item")
require("src/tactics/character/items/types")
local wpn = require("src/tactics/character/items/object/weapon")
local ITEM_DATA = require("src/tactics/data/items")

local record ItemGenerator
end

local function generate_weapon(def: WeaponDefinition): wpn.Weapon
	if def == nil then
		return nil
	end
	-- may need to copy data in the future
	return setmetatable({},{ __index = def})
end

function ItemGenerator.generate(item_id: string): Item.Item
	local data = ITEM_DATA[item_id]
	assert(data ~= nil)
	
	return Item.new(
		item_id,
		data.name,
		data.type,
		data.slots,
		data.equip_slot,
		data.sprite_data,
		data.equipment_effects,
		generate_weapon(data.weapon_definition)
	)
end

return ItemGenerator
