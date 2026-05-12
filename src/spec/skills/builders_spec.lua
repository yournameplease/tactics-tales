local luassert = require("luassert")
local point = require("src.tactics.util.point")
local builders = require("src.tactics.skills.builders")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local PLAYER = "player"
local ENEMY  = "enemy"

---@param id integer
---@param p Point
---@param side string
---@return table
local function make_unit(id, p, side)
    return { id = id, tile = p, side = side }
end

--- Build a minimal mock BattleMap backed by a tile→unit table.
---@param w integer
---@param h integer
---@param units table[] Units placed on the map.
---@return table
local function make_map(w, h, units)
    local tile_map = {}
    for _, u in ipairs(units) do
        local key = u.tile.x .. "," .. u.tile.y
        tile_map[key] = u
    end
    return {
        tile_is_in_map = function(_self, p)
            return p.x >= 0 and p.x < w and p.y >= 0 and p.y < h
        end,
        get_at_tile = function(_self, p)
            return tile_map[p.x .. "," .. p.y]
        end,
    }
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.skills.builders", function()
    -- -----------------------------------------------------------------------
    -- self_target
    -- -----------------------------------------------------------------------

    describe("self_target", function()
        it("get_selection_tiles returns only the origin", function()
            local origin = point.of(2, 2)
            local targeting = builders.self_target()
            local tiles = targeting.get_selection_tiles(origin, make_map(5, 5, {}), PLAYER)
            luassert.are_equal(1, #tiles)
            luassert.are_same(origin, tiles[1])
        end)

        it("get_targets_for_selection returns the unit at the caster tile", function()
            local origin = point.of(2, 2)
            local caster = make_unit(1, origin, PLAYER)
            local map = make_map(5, 5, { caster })
            local targeting = builders.self_target()
            local targets = targeting.get_targets_for_selection(origin, origin, map, PLAYER)
            luassert.are_equal(1, #targets)
            luassert.are_equal(caster, targets[1])
        end)

        it("is_target_valid is true for the origin", function()
            local origin = point.of(2, 2)
            local targeting = builders.self_target()
            luassert.is_true(targeting.is_target_valid(origin, origin, make_map(5, 5, {}), PLAYER))
        end)

        it("is_target_valid is false for any other tile", function()
            local origin = point.of(2, 2)
            local other = point.of(3, 2)
            local targeting = builders.self_target()
            luassert.is_false(targeting.is_target_valid(origin, other, make_map(5, 5, {}), PLAYER))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- ally_in_range
    -- -----------------------------------------------------------------------

    describe("ally_in_range", function()
        it("get_selection_tiles includes allies within range", function()
            local origin = point.of(2, 2)
            local ally = make_unit(2, point.of(3, 2), PLAYER)
            local targeting = builders.ally_in_range(1, 2)
            local tiles = targeting.get_selection_tiles(origin, make_map(5, 5, { ally }), PLAYER)
            luassert.are_equal(1, #tiles)
        end)

        it("get_selection_tiles excludes enemies", function()
            local origin = point.of(2, 2)
            local enemy = make_unit(3, point.of(3, 2), ENEMY)
            local targeting = builders.ally_in_range(1, 2)
            local tiles = targeting.get_selection_tiles(origin, make_map(5, 5, { enemy }), PLAYER)
            luassert.are_equal(0, #tiles)
        end)

        it("get_selection_tiles excludes allies beyond max range", function()
            local origin = point.of(0, 0)
            local far_ally = make_unit(2, point.of(3, 0), PLAYER)
            local targeting = builders.ally_in_range(1, 2)
            local tiles = targeting.get_selection_tiles(origin, make_map(5, 5, { far_ally }), PLAYER)
            luassert.are_equal(0, #tiles)
        end)

        it("is_target_valid is true for an ally in range", function()
            local origin = point.of(2, 2)
            local ally = make_unit(2, point.of(3, 2), PLAYER)
            local map = make_map(5, 5, { ally })
            local targeting = builders.ally_in_range(1, 2)
            luassert.is_true(targeting.is_target_valid(origin, ally.tile, map, PLAYER))
        end)

        it("is_target_valid is false for an out-of-range ally", function()
            local origin = point.of(0, 0)
            local ally = make_unit(2, point.of(4, 0), PLAYER)
            local map = make_map(5, 5, { ally })
            local targeting = builders.ally_in_range(1, 2)
            luassert.is_false(targeting.is_target_valid(origin, ally.tile, map, PLAYER))
        end)

        it("filter predicate restricts selectable allies", function()
            local origin = point.of(2, 2)
            local healthy = make_unit(2, point.of(3, 2), PLAYER)
            local map = make_map(5, 5, { healthy })
            local targeting = builders.ally_in_range(1, 2, function(_u) return false end)
            local tiles = targeting.get_selection_tiles(origin, map, PLAYER)
            luassert.are_equal(0, #tiles)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- enemy_in_range
    -- -----------------------------------------------------------------------

    describe("enemy_in_range", function()
        it("get_selection_tiles includes enemies in range", function()
            local origin = point.of(2, 2)
            local enemy = make_unit(3, point.of(3, 2), ENEMY)
            local targeting = builders.enemy_in_range(1, 2)
            local tiles = targeting.get_selection_tiles(origin, make_map(5, 5, { enemy }), PLAYER)
            luassert.are_equal(1, #tiles)
        end)

        it("get_selection_tiles excludes allies", function()
            local origin = point.of(2, 2)
            local ally = make_unit(2, point.of(3, 2), PLAYER)
            local targeting = builders.enemy_in_range(1, 2)
            local tiles = targeting.get_selection_tiles(origin, make_map(5, 5, { ally }), PLAYER)
            luassert.are_equal(0, #tiles)
        end)

        it("is_target_valid is false for an ally tile", function()
            local origin = point.of(2, 2)
            local ally = make_unit(2, point.of(3, 2), PLAYER)
            local map = make_map(5, 5, { ally })
            local targeting = builders.enemy_in_range(1, 2)
            luassert.is_false(targeting.is_target_valid(origin, ally.tile, map, PLAYER))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- adjacent_allies
    -- -----------------------------------------------------------------------

    describe("adjacent_allies", function()
        it("get_selection_tiles returns only the origin", function()
            local origin = point.of(2, 2)
            local targeting = builders.adjacent_allies()
            local tiles = targeting.get_selection_tiles(origin, make_map(5, 5, {}), PLAYER)
            luassert.are_equal(1, #tiles)
            luassert.are_same(origin, tiles[1])
        end)

        it("get_targets_for_selection returns all adjacent allies", function()
            local origin = point.of(2, 2)
            local a1 = make_unit(2, point.of(3, 2), PLAYER)
            local a2 = make_unit(3, point.of(2, 3), PLAYER)
            local enemy = make_unit(4, point.of(1, 2), ENEMY)
            local map = make_map(5, 5, { a1, a2, enemy })
            local targeting = builders.adjacent_allies()
            local targets = targeting.get_targets_for_selection(origin, origin, map, PLAYER)
            luassert.are_equal(2, #targets)
        end)

        it("is_target_valid is false when no adjacent allies exist", function()
            local origin = point.of(2, 2)
            local map = make_map(5, 5, {})
            local targeting = builders.adjacent_allies()
            luassert.is_false(targeting.is_target_valid(origin, origin, map, PLAYER))
        end)

        it("is_target_valid is true when at least one adjacent ally exists", function()
            local origin = point.of(2, 2)
            local ally = make_unit(2, point.of(3, 2), PLAYER)
            local map = make_map(5, 5, { ally })
            local targeting = builders.adjacent_allies()
            luassert.is_true(targeting.is_target_valid(origin, origin, map, PLAYER))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- adjacent_enemies
    -- -----------------------------------------------------------------------

    describe("adjacent_enemies", function()
        it("get_targets_for_selection returns all adjacent enemies", function()
            local origin = point.of(2, 2)
            local e1 = make_unit(3, point.of(3, 2), ENEMY)
            local e2 = make_unit(4, point.of(2, 1), ENEMY)
            local ally = make_unit(2, point.of(1, 2), PLAYER)
            local map = make_map(5, 5, { e1, e2, ally })
            local targeting = builders.adjacent_enemies()
            local targets = targeting.get_targets_for_selection(origin, origin, map, PLAYER)
            luassert.are_equal(2, #targets)
        end)

        it("is_target_valid is false when no adjacent enemies exist", function()
            local origin = point.of(2, 2)
            local ally = make_unit(2, point.of(3, 2), PLAYER)
            local map = make_map(5, 5, { ally })
            local targeting = builders.adjacent_enemies()
            luassert.is_false(targeting.is_target_valid(origin, origin, map, PLAYER))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- allies_in_range
    -- -----------------------------------------------------------------------

    describe("allies_in_range", function()
        it("get_selection_tiles returns only the origin", function()
            local origin = point.of(2, 2)
            local targeting = builders.allies_in_range(1, 3)
            local tiles = targeting.get_selection_tiles(origin, make_map(5, 5, {}), PLAYER)
            luassert.are_equal(1, #tiles)
            luassert.are_same(origin, tiles[1])
        end)

        it("get_targets_for_selection returns all allies in range", function()
            local origin = point.of(2, 2)
            local a1 = make_unit(2, point.of(3, 2), PLAYER)
            local a2 = make_unit(3, point.of(4, 2), PLAYER)
            local far = make_unit(4, point.of(0, 0), PLAYER)
            local enemy = make_unit(5, point.of(2, 3), ENEMY)
            local map = make_map(7, 7, { a1, a2, far, enemy })
            local targeting = builders.allies_in_range(1, 2)
            local targets = targeting.get_targets_for_selection(origin, origin, map, PLAYER)
            luassert.are_equal(2, #targets)
        end)

        it("is_target_valid is true for the origin", function()
            local origin = point.of(2, 2)
            local targeting = builders.allies_in_range(1, 2)
            luassert.is_true(targeting.is_target_valid(origin, origin, make_map(5, 5, {}), PLAYER))
        end)

        it("is_target_valid is false for any other tile", function()
            local origin = point.of(2, 2)
            local other = point.of(3, 2)
            local targeting = builders.allies_in_range(1, 2)
            luassert.is_false(targeting.is_target_valid(origin, other, make_map(5, 5, {}), PLAYER))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- make_heal
    -- -----------------------------------------------------------------------

    describe("make_heal", function()
        it("returns the correct name and heal effect", function()
            local t = builders.make_heal("Heal", 5, builders.self_target())
            luassert.are_equal("Heal", t.name)
            luassert.are_same({ type = "heal", amount = 5 }, t.effects[1])
        end)

        it("places hp_cost before heal when hp_cost is set", function()
            local t = builders.make_heal("Heal", 5, builders.self_target(), { hp_cost = 1 })
            luassert.are_equal(2, #t.effects)
            luassert.are_equal("hp_cost", t.effects[1].type)
            luassert.are_equal("heal", t.effects[2].type)
        end)

        it("sets cooldown and uses_per_battle from opts", function()
            local t = builders.make_heal("Heal", 5, builders.self_target(), {
                cooldown = 2, uses_per_battle = 3,
            })
            luassert.are_equal(2, t.cooldown)
            luassert.are_equal(3, t.uses_per_battle)
        end)

        it("cooldown and uses_per_battle are nil when not provided", function()
            local t = builders.make_heal("Heal", 5, builders.self_target())
            luassert.are_equal(nil, t.cooldown)
            luassert.are_equal(nil, t.uses_per_battle)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- make_damage
    -- -----------------------------------------------------------------------

    describe("make_damage", function()
        it("returns the correct name, damage, and accuracy", function()
            local t = builders.make_damage("Strike", 4, 90, builders.self_target())
            luassert.are_equal("Strike", t.name)
            luassert.are_same({ type = "damage", damage = 4, accuracy = 90 }, t.effects[1])
        end)

        it("places hp_cost before damage when hp_cost is set", function()
            local t = builders.make_damage("Strike", 4, 90, builders.self_target(), { hp_cost = 2 })
            luassert.are_equal(2, #t.effects)
            luassert.are_equal("hp_cost", t.effects[1].type)
            luassert.are_equal("damage", t.effects[2].type)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- make_debuff
    -- -----------------------------------------------------------------------

    describe("make_debuff", function()
        it("returns the correct debuff effect", function()
            local t = builders.make_debuff("Slow", "slow", 3, builders.self_target())
            luassert.are_same({ type = "debuff", kind = "slow", duration = 3 }, t.effects[1])
        end)
    end)

    -- -----------------------------------------------------------------------
    -- make_buff
    -- -----------------------------------------------------------------------

    describe("make_buff", function()
        it("returns the correct buff effect", function()
            local t = builders.make_buff("Haste", "haste", 2, builders.self_target())
            luassert.are_same({ type = "buff", kind = "haste", duration = 2 }, t.effects[1])
        end)
    end)
end)
