local luassert = require("luassert")
local battle_map = require("src.tactics.battle.battle_map")
local tile_reachability_cache = require("src.tactics.battle.tile_reachability_cache")
local point = require("src.tactics.util.point")
local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a WxH BattleMap with all tiles passable (cost 1, not solid).
---@param w integer
---@param h integer
---@return BattleMap
local function make_open_map(w, h)
    local map = battle_map.new(w, h, {})
    local ground = userdata("u8", w, h)
    -- sprite 1 → fget returns 0 → solid=false, movement_cost=1
    for x = 0, w - 1 do
        for y = 0, h - 1 do
            ground:set(x, y, 1)
        end
    end
    map.layers = { terrain = { ground = ground } }
    return map
end

--- Build a minimal unit-shaped table.
---@param id integer
---@param tile Point
---@param movement integer
---@param side? string
---@return table
local function make_unit(id, tile, movement, side)
    local s = side or "player"
    return {
        id = id,
        tile = tile,
        side = s,
        movement_side = s,
        marked = false,
        unit_ai = nil,
        is_marked = function(self) return self.marked end,
        is_player = function(self) return self.side == "player" end,
        character = {
            stats = { movement = movement },
            get_weapon_targeting = function()
                return {
                    get_selection_tiles = function(_tile, _map) return {} end,
                }
            end,
        },
    }
end

--- Place `unit` on the map at its current tile.
local function place_unit(map, unit)
    map:spawn_unit(unit, unit.tile)
end

--- Remove `unit` from the map (simulates death).
local function kill_unit(map, unit)
    map.units_by_id[unit.id] = nil
    map.units_by_x_y:set_point(unit.tile, nil)
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("battle.tile_reachability_cache", function()

    -- -----------------------------------------------------------------------
    -- get_valid_tiles_for_unit
    -- -----------------------------------------------------------------------

    describe("get_valid_tiles_for_unit", function()
        it("cache miss computes tiles and marks reachable tiles", function()
            local map = make_open_map(5, 5)
            local unit = make_unit(1, point.of(2, 2), 2)
            place_unit(map, unit)

            local cache = tile_reachability_cache.new(map)
            local tiles = cache:get_valid_tiles_for_unit(unit)

            -- The unit's own tile should be reachable and valid
            local v = tiles:get(2, 2)
            luassert.is_true((v & HIGHLIGHT.IS_REACHABLE) ~= 0, "unit tile should be IS_REACHABLE")
            luassert.is_true((v & HIGHLIGHT.IS_VALID) ~= 0, "unit tile should be IS_VALID")
        end)

        it("second call returns the cached value (same object)", function()
            local map = make_open_map(5, 5)
            local unit = make_unit(1, point.of(2, 2), 2)
            place_unit(map, unit)

            local cache = tile_reachability_cache.new(map)
            local first = cache:get_valid_tiles_for_unit(unit)
            local second = cache:get_valid_tiles_for_unit(unit)

            luassert.are_equal(first, second, "second call must return the cached object")
        end)
    end)

    -- -----------------------------------------------------------------------
    -- invalidate_tiles_for_point
    -- -----------------------------------------------------------------------

    describe("invalidate_tiles_for_point", function()
        it("evicts a unit whose movement range covers the invalidated point", function()
            local map = make_open_map(7, 7)
            local unit = make_unit(1, point.of(3, 3), 3)
            place_unit(map, unit)

            local cache = tile_reachability_cache.new(map)
            cache:get_valid_tiles_for_unit(unit)
            luassert.is_not_nil(cache.valid_tiles_by_unit[unit.id], "should be cached")

            -- point (3,4) is distance 1 from (3,3), within movement 3
            cache:invalidate_tiles_for_point(point.of(3, 4))

            luassert.is_nil(cache.valid_tiles_by_unit[unit.id], "cache should be evicted")
        end)

        it("does not evict a unit whose movement range does not cover the point", function()
            local map = make_open_map(10, 10)
            local unit = make_unit(1, point.of(0, 0), 1)
            place_unit(map, unit)

            local cache = tile_reachability_cache.new(map)
            cache:get_valid_tiles_for_unit(unit)

            -- point (9,9) is far beyond movement 1 from (0,0)
            cache:invalidate_tiles_for_point(point.of(9, 9))

            luassert.is_not_nil(cache.valid_tiles_by_unit[unit.id], "cache should remain")
        end)

        it("evicts a dead unit's cache entry on the next invalidation pass", function()
            local map = make_open_map(5, 5)
            local unit = make_unit(1, point.of(2, 2), 2)
            place_unit(map, unit)

            local cache = tile_reachability_cache.new(map)
            cache:get_valid_tiles_for_unit(unit)
            luassert.is_not_nil(cache.valid_tiles_by_unit[unit.id], "should be cached before death")

            kill_unit(map, unit)
            -- Any invalidate_tiles_for_point triggers the dead-unit cleanup
            cache:invalidate_tiles_for_point(point.of(0, 0))

            luassert.is_nil(cache.valid_tiles_by_unit[unit.id], "dead unit should be evicted")
        end)
    end)

    -- -----------------------------------------------------------------------
    -- invalidate_tiles_for_unit
    -- -----------------------------------------------------------------------

    describe("invalidate_tiles_for_unit", function()
        it("evicts the given unit's cache entry", function()
            local map = make_open_map(5, 5)
            local unit = make_unit(1, point.of(1, 1), 1)
            place_unit(map, unit)

            local cache = tile_reachability_cache.new(map)
            cache:get_valid_tiles_for_unit(unit)
            luassert.is_not_nil(cache.valid_tiles_by_unit[unit.id])

            cache:invalidate_tiles_for_unit(unit)

            luassert.is_nil(cache.valid_tiles_by_unit[unit.id])
        end)
    end)

    -- -----------------------------------------------------------------------
    -- marked_unit_tiles / recompute_marked_unit_tiles
    -- -----------------------------------------------------------------------

    describe("marked_unit_tiles", function()
        it("starts zeroed", function()
            local map = make_open_map(5, 5)
            local cache = tile_reachability_cache.new(map)
            luassert.are_equal(0, cache.marked_unit_tiles:get(0, 0))
        end)
    end)
end)
