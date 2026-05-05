local luassert = require("luassert")

local item_generator = require("src.tactics.character.items.item_generator")

local function make_item_data(overrides)
    local base = {
        name = "Test Sword",
        type = "WEAPON",
        slots = 1,
        equip_slot = "MAIN_HAND",
        sprite_data = { sprite = 1, anchor = { x = 0, y = 0 } },
        equipment_effects = {},
        appearance_overrides = nil,
        weapon_definition = nil,
    }
    if overrides then
        for k, v in pairs(overrides) do
            base[k] = v
        end
    end
    return base
end

describe("tactics.character.items.item_generator", function()
    describe("generate", function()
        it("should create an item with all fields from item_data", function()
            local item_data = {
                sword = make_item_data()
            }

            local item = item_generator.generate("sword", item_data)

            luassert.are_equal("sword", item.id)
            luassert.are_equal("Test Sword", item.name)
            luassert.are_equal("WEAPON", item.type)
            luassert.are_equal(1, item.slots)
            luassert.are_equal("MAIN_HAND", item.equip_slot)
        end)

        it("should set weapon to nil when weapon_definition is nil", function()
            local item_data = {
                potion = make_item_data({
                    name = "Potion",
                    type = "CONSUMABLE",
                    equip_slot = "NONE",
                    weapon_definition = nil,
                })
            }

            local item = item_generator.generate("potion", item_data)

            luassert.is_nil(item.weapon)
        end)

        it("should create a weapon that inherits fields from weapon_definition", function()
            local weapon_def = {
                name = "Iron Sword",
                sprite = 42,
                damage = 5,
                accuracy = 80,
                type = "MELEE",
                body_type = "BACK_HAND",
                effects = {},
            }
            local item_data = {
                iron_sword = make_item_data({ weapon_definition = weapon_def })
            }

            local item = item_generator.generate("iron_sword", item_data)

            luassert.is_not_nil(item.weapon)
            luassert.are_equal(5, item.weapon.damage)
            luassert.are_equal(80, item.weapon.accuracy)
            luassert.are_equal("MELEE", item.weapon.type)
            luassert.are_equal("BACK_HAND", item.weapon.body_type)
        end)

        it("should error when item_id is not found in item_data", function()
            local item_data = {}

            luassert.has_error(function()
                item_generator.generate("missing_item", item_data)
            end)
        end)
    end)
end)
