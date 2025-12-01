local Item = require("src/character/items/object/item")
require("src/character/items/types")
require("src/character/weapons")

local record ItemInventoryModule
	interface ItemInventory

		-- items will be indexed, to account for slots
		get_items: function(self): { integer: Item }
		get_equipped_items: function(self): { EquipSlot: Item }
		
		add_item: function(self, item: Item.Item)
		equip_item: function(self, slot: integer)
		unequip_item: function(self, slot: integer)
		remove_item: function(self, slot: integer)
		move_item: function(self, slot: integer, before_slot: integer)
	end
end

local record ItemInventoryImpl
	is ItemInventoryModule.ItemInventory

	record InventoryItem
		item: Item
		equip_slot: EquipSlot
	end
	
	items: { InventoryItem }

end




return ItemInventoryModule
