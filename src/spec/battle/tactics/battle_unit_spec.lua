require("src.spec.picotron_shim")

local luassert = require("luassert")
local battle_unit = require("src.tactics.battle.tactics.battle_unit")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a minimal Character mock.
---@param opts table? fields: id, name, hp_max, dead, tags
---@return table
local function make_character(opts)
    opts = opts or {}
    return {
        id = opts.id or 1,
        name = opts.name or "TestChar",
        stats = { hp_max = opts.hp_max or 10 },
        dead = opts.dead or false,
        tags = opts.tags or {},
    }
end

--- Spawn a BattleUnit with sensible defaults.
---@param opts table? fields: character, tile, tags, side, movement_side, facing, ai
---@return BattleUnit
local function make_unit(opts)
    opts = opts or {}
    local char = opts.character or make_character()
    local tile = opts.tile or { x = 1, y = 1 }
    local tags = opts.tags or {}
    local side = opts.side or "player"
    local movement_side = opts.movement_side
    local facing = opts.facing or { vertical = "down", horizontal = "right" }
    local ai = opts.ai or { move = "one", target_sides = {}, exclude_tags = {} }
    return battle_unit.spawn_unit(char, tile, tags, side, movement_side, facing, ai)
end

-- ---------------------------------------------------------------------------
-- spawn_unit
-- ---------------------------------------------------------------------------

describe("battle.tactics.battle_unit", function()
    describe("spawn_unit", function()
        it("should initialise hp_current from character hp_max", function()
            local char = make_character({ hp_max = 25 })
            local unit = make_unit({ character = char })
            luassert.are_equal(25, unit.hp_current)
        end)

        it("should set has_acted to false", function()
            local unit = make_unit()
            luassert.is_false(unit.has_acted)
        end)

        it("should set marked to false", function()
            local unit = make_unit()
            luassert.is_false(unit.marked)
        end)

        it("should merge spawned tags with character tags", function()
            local char = make_character({ tags = { boss = true } })
            local unit = make_unit({ character = char, tags = { "hero" } })
            luassert.is_true(unit.tags["hero"])
            luassert.is_true(unit.tags["boss"])
        end)

        it("should default movement_side to side when not provided", function()
            local unit = make_unit({ side = "enemy", movement_side = nil })
            luassert.are_equal("enemy", unit.movement_side)
        end)

        it("should use provided movement_side when given", function()
            local unit = make_unit({ side = "enemy", movement_side = "neutral" })
            luassert.are_equal("neutral", unit.movement_side)
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- Side queries
    -- ---------------------------------------------------------------------------

    describe("is_player", function()
        it("should return true for player side", function()
            local unit = make_unit({ side = "player" })
            luassert.is_true(unit:is_player())
        end)

        it("should return false for enemy side", function()
            local unit = make_unit({ side = "enemy" })
            luassert.is_false(unit:is_player())
        end)
    end)

    describe("is_enemy", function()
        it("should return true for enemy side", function()
            local unit = make_unit({ side = "enemy" })
            luassert.is_true(unit:is_enemy())
        end)

        it("should return false for player side", function()
            local unit = make_unit({ side = "player" })
            luassert.is_false(unit:is_enemy())
        end)
    end)

    describe("is_neutral", function()
        it("should return true for neutral side", function()
            local unit = make_unit({ side = "neutral" })
            luassert.is_true(unit:is_neutral())
        end)

        it("should return false for player side", function()
            local unit = make_unit({ side = "player" })
            luassert.is_false(unit:is_neutral())
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- Tag queries
    -- ---------------------------------------------------------------------------

    describe("has_tag (method)", function()
        it("should return true when the unit has the tag", function()
            local unit = make_unit({ tags = { "flyer" } })
            luassert.is_true(unit:has_tag("flyer"))
        end)

        it("should return falsy when the unit does not have the tag", function()
            local unit = make_unit({ tags = {} })
            luassert.is_falsy(unit:has_tag("flyer"))
        end)
    end)

    describe("has_tag (predicate factory)", function()
        it("should return a function that checks the tag", function()
            local predicate = battle_unit.has_tag("flyer")
            local unit_with = make_unit({ tags = { "flyer" } })
            local unit_without = make_unit({ tags = {} })
            luassert.is_true(predicate(unit_with))
            luassert.is_falsy(predicate(unit_without))
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- Marked
    -- ---------------------------------------------------------------------------

    describe("is_marked", function()
        it("should return false when not marked", function()
            local unit = make_unit()
            luassert.is_false(unit:is_marked())
        end)

        it("should return true when marked is set", function()
            local unit = make_unit()
            unit.marked = true
            luassert.is_true(unit:is_marked())
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- Alive / dead
    -- ---------------------------------------------------------------------------

    describe("is_alive / is_dead", function()
        it("should be alive when character.dead is false", function()
            local unit = make_unit({ character = make_character({ dead = false }) })
            luassert.is_true(unit:is_alive())
            luassert.is_false(unit:is_dead())
        end)

        it("should be dead when character.dead is true", function()
            local unit = make_unit({ character = make_character({ dead = true }) })
            luassert.is_false(unit:is_alive())
            luassert.is_true(unit:is_dead())
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- take_damage
    -- ---------------------------------------------------------------------------

    describe("take_damage", function()
        it("should reduce hp by the given amount", function()
            local char = make_character({ hp_max = 10 })
            local unit = make_unit({ character = char })
            unit:take_damage(3)
            luassert.are_equal(7, unit.hp_current)
        end)

        it("should clamp hp to 0 when damage exceeds current hp", function()
            local char = make_character({ hp_max = 10 })
            local unit = make_unit({ character = char })
            unit:take_damage(999)
            luassert.are_equal(0, unit.hp_current)
        end)

        it("should not increase hp above hp_max", function()
            local char = make_character({ hp_max = 10 })
            local unit = make_unit({ character = char })
            unit.hp_current = 5
            unit:take_damage(-5)
            luassert.are_equal(10, unit.hp_current)
        end)
    end)

    -- ---------------------------------------------------------------------------
    -- die
    -- ---------------------------------------------------------------------------

    describe("die", function()
        it("should set character.dead to true", function()
            local char = make_character({ dead = false })
            local unit = make_unit({ character = char, tags = { "hero" } })
            unit:die()
            luassert.is_true(char.dead)
        end)
    end)
end)
