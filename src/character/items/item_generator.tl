local Item = require("src/character/items/object/item")
require("src/character/items/types")
local ITEM_DATA = require("src/data/items")

local record ItemGenerator
end

local function generate_weapon(def: WeaponDefinition): Weapon
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
		generate_weapon(data.weapon_definition)
	)
end

return ItemGenerator
