local luassert = require("luassert")

local item_mod = require("src.tactics.character.items.object.item")
local item_inventory_mod = require("src.tactics.character.items.object.item_inventory")

local function make_item(overrides)
    local base = {
        id = "test_item",
        name = "Test Item",
        type = "WEAPON",
        slots = 1,
        equip_slot = "MAIN_HAND",
        sprite_data = {sprite = 1, anchor = {x = 0, y = 0}},
        equipment_effects = {},
        appearance_overrides = nil,
        weapon = nil,
    }
    if overrides then
        for k, v in pairs(overrides) do
            base[k] = v
        end
    end
    return item_mod.new(
        base.id,
        base.name,
        base.type,
        base.slots,
        base.equip_slot,
        base.sprite_data,
        base.equipment_effects,
        base.appearance_overrides,
        base.weapon
    )
end

describe("tactics.character.items.object.item_inventory", function()
    describe("new", function()
        it("should create an empty inventory with the given max_slots", function()
            local inv = item_inventory_mod.new(8)

            luassert.are_equal(8, inv:get_max_slots())
            luassert.are_same({}, inv:get_items())
        end)
    end)

    describe("can_add_item / add_item", function()
        it("should allow adding an item when slots are available", function()
            local inv = item_inventory_mod.new(4)
            local item = make_item({slots = 2})

            luassert.is_true(inv:can_add_item(item))
        end)

        it("should reject adding an item when capacity would be exceeded", function()
            local inv = item_inventory_mod.new(2)
            local item_a = make_item({id = "a", slots = 1})
            local item_b = make_item({id = "b", slots = 2})
            inv:add_item(item_a)

            luassert.is_false(inv:can_add_item(item_b))
        end)

        it("should add item and update slot mapping", function()
            local inv = item_inventory_mod.new(4)
            local item = make_item({id = "sword", slots = 2})

            inv:add_item(item)

            local items = inv:get_items()
            luassert.are_equal(1, #items)
            luassert.are_equal("sword", items[1].id)

            local by_slot = inv:get_items_by_slot()
            luassert.is_not_nil(by_slot[1])
            luassert.are_equal("sword", by_slot[1].id)
        end)

        it("should error when adding an item that exceeds capacity", function()
            local inv = item_inventory_mod.new(1)
            local item = make_item({slots = 2})

            luassert.has_error(function()
                inv:add_item(item)
            end)
        end)
    end)

    describe("can_equip", function()
        it("should allow equipping TWO_HANDS when no hand slots are used", function()
            local inv = item_inventory_mod.new(4)
            local item = make_item({equip_slot = "TWO_HANDS", slots = 2})
            inv:add_item(item)

            luassert.is_true(inv:can_equip(1))
        end)

        it("should block TWO_HANDS when MAIN_HAND is already equipped", function()
            local inv = item_inventory_mod.new(4)
            local main = make_item({id = "main", equip_slot = "MAIN_HAND"})
            local two = make_item({id = "two", equip_slot = "TWO_HANDS", slots = 2})
            inv:add_item(main)
            inv:add_item(two)
            inv:equip_item(1)

            luassert.is_false(inv:can_equip(2))
        end)

        it("should block MAIN_HAND when TWO_HANDS is already equipped", function()
            local inv = item_inventory_mod.new(4)
            local two = make_item({id = "two", equip_slot = "TWO_HANDS", slots = 2})
            local main = make_item({id = "main", equip_slot = "MAIN_HAND"})
            inv:add_item(two)
            inv:add_item(main)
            inv:equip_item(1)

            luassert.is_false(inv:can_equip(2))
        end)

        it("should block OFF_HAND when TWO_HANDS is already equipped", function()
            local inv = item_inventory_mod.new(4)
            local two = make_item({id = "two", equip_slot = "TWO_HANDS", slots = 2})
            local off = make_item({id = "off", equip_slot = "OFF_HAND"})
            inv:add_item(two)
            inv:add_item(off)
            inv:equip_item(1)

            luassert.is_false(inv:can_equip(2))
        end)

        it("should block BODY when a body item is already equipped", function()
            local inv = item_inventory_mod.new(4)
            local armor_a = make_item({id = "armor_a", type = "ARMOR", equip_slot = "BODY"})
            local armor_b = make_item({id = "armor_b", type = "ARMOR", equip_slot = "BODY"})
            inv:add_item(armor_a)
            inv:add_item(armor_b)
            inv:equip_item(1)

            luassert.is_false(inv:can_equip(2))
        end)
    end)

    describe("equip_item / unequip_item", function()
        it("should equip an item and report it as equipped", function()
            local inv = item_inventory_mod.new(4)
            local item = make_item({equip_slot = "MAIN_HAND"})
            inv:add_item(item)

            inv:equip_item(1)

            luassert.is_true(inv:is_equipped(1))
        end)

        it("should unequip an item when requested", function()
            local inv = item_inventory_mod.new(4)
            local item = make_item({equip_slot = "MAIN_HAND"})
            inv:add_item(item)
            inv:equip_item(1)

            inv:unequip_item(1)

            luassert.is_false(inv:is_equipped(1))
        end)

        it("equipping TWO_HANDS should unequip MAIN_HAND and OFF_HAND", function()
            local inv = item_inventory_mod.new(6)
            local main = make_item({id = "main", equip_slot = "MAIN_HAND"})
            local off = make_item({id = "off", equip_slot = "OFF_HAND"})
            local two = make_item({id = "two", equip_slot = "TWO_HANDS", slots = 2})
            inv:add_item(main)
            inv:add_item(off)
            inv:add_item(two)
            inv:equip_item(1)
            inv:equip_item(2)

            inv:equip_item(3)

            luassert.is_false(inv:is_equipped(1))
            luassert.is_false(inv:is_equipped(2))
            luassert.is_true(inv:is_equipped(3))
        end)

        it("equipping MAIN_HAND should unequip TWO_HANDS", function()
            local inv = item_inventory_mod.new(4)
            local two = make_item({id = "two", equip_slot = "TWO_HANDS", slots = 2})
            local main = make_item({id = "main", equip_slot = "MAIN_HAND"})
            inv:add_item(two)
            inv:add_item(main)
            inv:equip_item(1)

            inv:equip_item(2)

            luassert.is_false(inv:is_equipped(1))
            luassert.is_true(inv:is_equipped(2))
        end)
    end)

    describe("get_equipped_weapons", function()
        it("should return weapons equipped in hand slots", function()
            local mock_weapon = {damage = 10, accuracy = 90, type = "MELEE", body_type = "BACK_HAND", effects = {}}
            local inv = item_inventory_mod.new(4)
            local sword = make_item({id = "sword", equip_slot = "MAIN_HAND", weapon = mock_weapon})
            inv:add_item(sword)
            inv:equip_item(1)

            local weapons = inv:get_equipped_weapons()

            luassert.are_equal(1, #weapons)
            luassert.are_equal(10, weapons[1].damage)
        end)

        it("should not return non-weapon items from hand slots", function()
            local inv = item_inventory_mod.new(4)
            local shield = make_item({id = "shield", type = "SHIELD", equip_slot = "OFF_HAND", weapon = nil})
            inv:add_item(shield)
            inv:equip_item(1)

            local weapons = inv:get_equipped_weapons()

            luassert.are_equal(0, #weapons)
        end)
    end)

    describe("get_item_descriptions", function()
        it("should return descriptions for equipped items with weapon effects", function()
            local mock_weapon = {
                damage = 5,
                accuracy = 70,
                type = "MELEE",
                body_type = "BACK_HAND",
                effects = {{type = "long_reach"}},
            }
            local inv = item_inventory_mod.new(4)
            local sword = make_item({id = "sword", name = "Long Sword", weapon = mock_weapon})
            inv:add_item(sword)
            inv:equip_item(1)

            local descriptions = inv:get_item_descriptions()

            luassert.are_equal(1, #descriptions)
            luassert.are_equal("Long Sword", descriptions[1].name)
            luassert.are_equal(1, #descriptions[1].effects)
            luassert.are_equal("Long Reach", descriptions[1].effects[1].name)
        end)

        it("should return descriptions for equipped items with equipment effects", function()
            local inv = item_inventory_mod.new(4)
            local armor = make_item({
                id = "armor",
                name = "Iron Armor",
                type = "ARMOR",
                equip_slot = "BODY",
                weapon = nil,
                equipment_effects = {{type = "increase_defense", amount = 3, defense_type = "ARMOR"}},
            })
            inv:add_item(armor)
            inv:equip_item(1)

            local descriptions = inv:get_item_descriptions()

            luassert.are_equal(1, #descriptions)
            luassert.are_equal("Iron Armor", descriptions[1].name)
            luassert.are_equal(1, #descriptions[1].effects)
            luassert.are_equal("Reduce damage taken by 3, to a minimum of 1.", descriptions[1].effects[1].description)
        end)
    end)
end)
