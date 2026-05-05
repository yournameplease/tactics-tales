local luassert = require("luassert")
local unit_spawner = require("src.tactics.battle.unit_spawner")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function make_char(id)
    return { id = id or 1, name = "char" .. (id or 1), stats = { hp_max = 10, movement = 3 },
             dead = false, tags = {}, skill_loadout = {} }
end

local function make_char_man(generated_char)
    local persisted = {}
    return {
        generate_character = function(_, _, _)
            return generated_char or make_char(99)
        end,
        persist_player = function(_, char)
            table.insert(persisted, char)
        end,
        _persisted = persisted,
    }
end

local function make_engine(tile_at, map_width)
    local spawned = {}
    return {
        battle_map = {
            get_at_tile = function(_, _) return tile_at end,
            width = map_width or 10,
        },
        skill_defs = {},
        spawn_unit = function(_, unit, pt)
            table.insert(spawned, { unit = unit, pt = pt })
        end,
        _spawned = spawned,
    }
end

-- ---------------------------------------------------------------------------
-- resolve_character
-- ---------------------------------------------------------------------------

describe("battle.unit_spawner", function()
    describe("resolve_character", function()
        it("template source always spawns a new character", function()
            local generated = make_char(5)
            local char_man = make_char_man(generated)
            local source = { type = "template", template = "warrior" }
            local char, count = unit_spawner.resolve_character(char_man, {}, 1, source, "enemy")
            luassert.are_equal(generated, char)
            luassert.are_equal(1, count)
        end)

        it("template source with player side persists the character", function()
            local generated = make_char(5)
            local char_man = make_char_man(generated)
            local source = { type = "template", template = "hero" }
            unit_spawner.resolve_character(char_man, {}, 1, source, "player")
            luassert.are_equal(1, #char_man._persisted)
            luassert.are_equal(generated, char_man._persisted[1])
        end)

        it("player_roster source consumes roster entries in order", function()
            local char_man = make_char_man()
            local roster = { make_char(1), make_char(2), make_char(3) }
            local source = { type = "player_roster" }

            local char1, count1 = unit_spawner.resolve_character(char_man, roster, 1, source, "player")
            luassert.are_equal(roster[1], char1)
            luassert.are_equal(2, count1)

            local char2, count2 = unit_spawner.resolve_character(char_man, roster, count1, source, "player")
            luassert.are_equal(roster[2], char2)
            luassert.are_equal(3, count2)
        end)

        it("player_roster source returns nil when roster is exhausted", function()
            local char_man = make_char_man()
            local roster = { make_char(1) }
            local source = { type = "player_roster" }
            local char, count = unit_spawner.resolve_character(char_man, roster, 2, source, "player")
            luassert.is_nil(char)
            luassert.are_equal(2, count)
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- try_spawn_at
    -- ---------------------------------------------------------------------------

    describe("try_spawn_at", function()
        local function make_source(type)
            if type == "template" then
                return { type = "template", template = "t" }
            end
            return { type = "player_roster" }
        end

        it("blocked tile + prevent → returns nil without spawning", function()
            local existing = make_char(77)
            local engine = make_engine(existing)
            local char_man = make_char_man(make_char(5))
            local roster = {}
            local pt = { x = 3, y = 3 }
            local unit, count = unit_spawner.try_spawn_at(
                engine, char_man, roster, 1, pt, make_source("template"),
                "enemy", nil, nil, {}, "prevent"
            )
            luassert.is_nil(unit)
            luassert.are_equal(1, count)
            luassert.are_equal(0, #engine._spawned)
        end)

        it("clear tile + template source → unit is spawned", function()
            local engine = make_engine(nil)
            local generated = make_char(5)
            local char_man = make_char_man(generated)
            local pt = { x = 3, y = 3 }
            local unit, count = unit_spawner.try_spawn_at(
                engine, char_man, {}, 1, pt, make_source("template"),
                "enemy", nil, { move = "one", target_sides = {}, exclude_tags = {} }, {}, "prevent"
            )
            luassert.is_not_nil(unit)
            luassert.are_equal(1, count)
            luassert.are_equal(1, #engine._spawned)
        end)

        it("clear tile + exhausted roster → nil, nothing spawned", function()
            local engine = make_engine(nil)
            local char_man = make_char_man()
            local roster = { make_char(1) }
            local pt = { x = 3, y = 3 }
            local unit, count = unit_spawner.try_spawn_at(
                engine, char_man, roster, 2, pt, make_source("player_roster"),
                "player", nil, nil, {}, "prevent"
            )
            luassert.is_nil(unit)
            luassert.are_equal(2, count)
            luassert.are_equal(0, #engine._spawned)
        end)
    end)
end)
