local luassert = require("luassert")
local character_manager = require("src.tactics.character.character_manager")

local function make_game_data()
    local function opt_static(v) return { type = "static", option = v } end
    local function opt_list(opts) return { type = "list", options = opts } end

    return {
        characters = {
            ["default"] = {
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
                hair_color_options  = opt_static("brown"),
                hair_options_m   = opt_static("short"),
                hair_options_f   = opt_static("bob_a"),
                beard_options    = opt_static("none"),
                eye_options      = opt_static("a"),
            }
        },
        items = {},
    }
end

describe("tactics.character.character_manager", function()
    describe("new", function()
        it("should create a manager", function()
            local game_data = make_game_data()

            local manager = character_manager.new(game_data)

            luassert.is_not_nil(manager)
        end)
    end)

    describe("generate_character", function()
        it("should return a character with expected stats", function()
            local game_data = make_game_data()
            local manager = character_manager.new(game_data)

            local char = manager:generate_character(nil, {})

            luassert.is_not_nil(char)
            luassert.are_equal(3, char.stats.movement)
            luassert.are_equal(4, char.stats.hp_max)
        end)

        it("should assign tags to the generated character", function()
            local game_data = make_game_data()
            local manager = character_manager.new(game_data)

            local char = manager:generate_character(nil, {"enemy"})

            luassert.is_true(char.tags["enemy"])
        end)
    end)

    describe("persist_player and get_player_roster", function()
        it("should include persisted characters in the roster", function()
            local game_data = make_game_data()
            local manager = character_manager.new(game_data)
            local char = manager:generate_character(nil, {})

            manager:persist_player(char)
            local roster = manager:get_player_roster()

            luassert.are_equal(1, #roster)
            luassert.are_equal(char.id, roster[1].id)
        end)

        it("should exclude dead characters from the roster", function()
            local game_data = make_game_data()
            local manager = character_manager.new(game_data)
            local char = manager:generate_character(nil, {})
            char.dead = true

            manager:persist_player(char)
            local roster = manager:get_player_roster()

            luassert.are_equal(0, #roster)
        end)

        it("should only include living characters when roster is mixed", function()
            local game_data = make_game_data()
            local manager = character_manager.new(game_data)
            local alive = manager:generate_character(nil, {})
            local dead  = manager:generate_character(nil, {})
            dead.dead = true

            manager:persist_player(alive)
            manager:persist_player(dead)
            local roster = manager:get_player_roster()

            luassert.are_equal(1, #roster)
            luassert.are_equal(alive.id, roster[1].id)
        end)
    end)

    describe("get_full_roster", function()
        it("includes living characters", function()
            local manager = character_manager.new(make_game_data())
            local char = manager:generate_character(nil, {})
            manager:persist_player(char)
            local roster = manager:get_full_roster()
            luassert.are_equal(1, #roster)
            luassert.are_equal(char.id, roster[1].id)
        end)

        it("includes dead characters", function()
            local manager = character_manager.new(make_game_data())
            local char = manager:generate_character(nil, {})
            char.dead = true
            manager:persist_player(char)
            local roster = manager:get_full_roster()
            luassert.are_equal(1, #roster)
            luassert.are_equal(char.id, roster[1].id)
        end)

        it("includes both living and dead characters", function()
            local manager = character_manager.new(make_game_data())
            local alive = manager:generate_character(nil, {})
            local dead  = manager:generate_character(nil, {})
            dead.dead = true
            manager:persist_player(alive)
            manager:persist_player(dead)
            local roster = manager:get_full_roster()
            luassert.are_equal(2, #roster)
        end)

        it("does not affect get_player_roster", function()
            local manager = character_manager.new(make_game_data())
            local alive = manager:generate_character(nil, {})
            local dead  = manager:generate_character(nil, {})
            dead.dead = true
            manager:persist_player(alive)
            manager:persist_player(dead)
            luassert.are_equal(1, #manager:get_player_roster())
            luassert.are_equal(2, #manager:get_full_roster())
        end)
    end)

    describe("get_character", function()
        it("should return nil for an unknown id", function()
            local game_data = make_game_data()
            local manager = character_manager.new(game_data)

            luassert.is_nil(manager:get_character(999))
        end)

        it("should return the character after persist_player", function()
            local game_data = make_game_data()
            local manager = character_manager.new(game_data)
            local char = manager:generate_character(nil, {})
            manager:persist_player(char)

            local found = manager:get_character(char.id)
            assert(found)
            luassert.are_equal(char.id, found.id)
        end)
    end)
end)
