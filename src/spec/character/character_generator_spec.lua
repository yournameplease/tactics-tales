local luassert = require("luassert")
local character_generator = require("src.tactics.character.character_generator")
local maps = require("src.tactics.util.maps")

-- Minimal game_data fixture with a single "default" template.
-- All appearance options use static or single-element list so the generator
-- always resolves without needing to control randomisation.
local function make_game_data(overrides)
    local function opt_list(opts) return { type = "list", options = opts } end
    local function opt_static(v)  return { type = "static", option = v } end

    local default_template = {
        movement = 3,
        hp_max = 4,
        item_loadout = {},
        head_options_m   = opt_list{"round"},
        head_options_f   = opt_list{"round"},
        eyewear_options  = opt_static("none"),
        headwear_options = opt_static("none"),
        body_options     = opt_static("default"),
        gender_options   = opt_list{"male", "female"},
        skin_color_options  = opt_static("a"),
        -- brown and dark_grey differ from skin "a" (colors[1] = 15), so no loop
        hair_color_options  = opt_static("brown"),
        hair_options_m   = opt_static("short"),
        hair_options_f   = opt_static("bob_a"),
        beard_options    = opt_static("none"),
        eye_options      = opt_static("a"),
    }

    if overrides then
        for k, v in pairs(overrides) do
            default_template[k] = v
        end
    end

    return {
        characters = { ["default"] = default_template },
        items = {},
    }
end

local function make_dagger_item_data()
    return {
        name = "Dagger",
        type = "WEAPON",
        slots = 1,
        equip_slot = "MAIN_HAND",
        sprite_data = { sprite = 1, anchor = { x = 0, y = 0 } },
        equipment_effects = {},
        appearance_overrides = nil,
        weapon_definition = {
            name = "Dagger",
            sprite = 1,
            damage = 2,
            accuracy = 90,
            type = "MELEE",
            body_type = "BACK_HAND",
            effects = {},
        },
    }
end

describe("tactics.character.character_generator", function()
    describe("generate_from_template", function()
        it("should return a character with required top-level fields", function()
            local game_data = make_game_data()

            local char = character_generator.generate_from_template(1, nil, {}, game_data)

            luassert.is_not_nil(char)
            luassert.are_equal(1, char.id)
            luassert.is_not_nil(char.name)
            luassert.is_not_nil(char.appearance)
            luassert.is_not_nil(char.stats)
            luassert.is_not_nil(char.inventory)
            luassert.is_not_nil(char.tags)
        end)

        it("should set stats from the template", function()
            local game_data = make_game_data()

            local char = character_generator.generate_from_template(1, nil, {}, game_data)

            luassert.are_equal(3, char.stats.movement)
            luassert.are_equal(4, char.stats.hp_max)
            luassert.are_equal(0, char.stats.def)
        end)

        it("should set tags from the tags argument", function()
            local game_data = make_game_data()

            local char = character_generator.generate_from_template(1, nil, {"warrior", "enemy"}, game_data)

            luassert.is_true(char.tags["warrior"])
            luassert.is_true(char.tags["enemy"])
        end)

        it("should produce an empty inventory when item_loadout is empty", function()
            local game_data = make_game_data()

            local char = character_generator.generate_from_template(1, nil, {}, game_data)

            luassert.are_equal(0, #char.inventory:get_items())
        end)

        it("should populate the inventory from item_loadout", function()
            local game_data = make_game_data({ item_loadout = { "dagger" } })
            game_data.items["dagger"] = make_dagger_item_data()

            local char = character_generator.generate_from_template(1, nil, {}, game_data)

            local items = char.inventory:get_items()
            luassert.are_equal(1, #items)
            luassert.are_equal("dagger", items[1].id)
        end)

        it("should equip loadout items when possible", function()
            local game_data = make_game_data({ item_loadout = { "dagger" } })
            game_data.items["dagger"] = make_dagger_item_data()

            local char = character_generator.generate_from_template(1, nil, {}, game_data)

            local equipped = char.inventory:get_equipped_items()
            luassert.is_not_nil(equipped["MAIN_HAND"])
        end)

        it("should use the id passed in", function()
            local game_data = make_game_data()

            local char = character_generator.generate_from_template(42, nil, {}, game_data)

            luassert.are_equal(42, char.id)
        end)
    end)

    describe("deserialize", function()
        it("should restore id, name, appearance, stats and tags from serialized data", function()
            local game_data = make_game_data()
            local serialized = {
                id = 7,
                name = "Aria",
                appearance = {
                    gender = "female",
                    head = "round",
                    hair = "bob_a",
                    skin = "a",
                    hair_color = "brown",
                    body_class = "default",
                    beard = "none",
                    eyes = "a",
                    eyewear = "none",
                    headwear = "none",
                },
                stats = { hp_max = 6, movement = 4, def = 1 },
                inventory = {},
                tags = maps.set({"player"}),
            }

            local char = character_generator.deserialize(serialized, game_data)

            luassert.are_equal(7, char.id)
            luassert.are_equal("Aria", char.name)
            luassert.are_equal(6, char.stats.hp_max)
            luassert.are_equal(4, char.stats.movement)
            luassert.is_true(char.tags["player"])
        end)

        it("should produce an empty inventory when serialized inventory is empty", function()
            local game_data = make_game_data()
            local serialized = {
                id = 1, name = "Test",
                appearance = {},
                stats = { hp_max = 4, movement = 3, def = 0 },
                inventory = {},
                tags = {},
            }

            local char = character_generator.deserialize(serialized, game_data)

            luassert.are_equal(0, #char.inventory:get_items())
        end)

        it("should restore inventory items from serialized ids", function()
            local game_data = make_game_data()
            game_data.items["dagger"] = make_dagger_item_data()
            local serialized = {
                id = 1, name = "Test",
                appearance = {},
                stats = { hp_max = 4, movement = 3, def = 0 },
                inventory = { "dagger" },
                tags = {},
            }

            local char = character_generator.deserialize(serialized, game_data)

            local items = char.inventory:get_items()
            luassert.are_equal(1, #items)
            luassert.are_equal("dagger", items[1].id)
        end)
    end)
end)
