local luassert = require("luassert")
local battle_map = require("src.tactics.battle.battle_map")
local point = require("src.tactics.util.point")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a minimal unit-shaped table.
---@param id integer
---@param tile Point
---@param side? string
---@return table
local function make_unit(id, tile, side)
    return { id = id, tile = tile, side = side or "player" }
end

--- Build a 5x5 BattleMap with no labels.
---@return BattleMap
local function make_map()
    return battle_map.new(5, 5, {})
end

--- Build a minimal MapLayers table backed by real MockUserdata.
---@param w integer
---@param h integer
---@return MapLayers
local function make_layers(w, h)
    return {
        terrain = {
            ground    = userdata("u8", w, h),
            back_wall = userdata("u8", w, h),
            mid_wall  = userdata("u8", w, h),
            front_wall = userdata("u8", w, h),
        }
    }
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("battle.battle_map", function()

    -- -----------------------------------------------------------------------
    -- battle_map.new
    -- -----------------------------------------------------------------------

    describe("new", function()
        it("should set width and height", function()
            local map = battle_map.new(8, 6, {})
            luassert.are_equal(8, map.width)
            luassert.are_equal(6, map.height)
        end)

        it("should start with no active units", function()
            local map = make_map()
            luassert.are_same({}, map.units_by_id)
        end)

        it("should start with no dead units", function()
            local map = make_map()
            luassert.are_equal(0, #map.dead_units)
        end)

        it("should store provided tile labels", function()
            local labels = { spawn = { point.of(1, 2) } }
            local map = battle_map.new(5, 5, labels)
            luassert.are_equal(1, #map.tile_labels["spawn"])
        end)
    end)

    -- -----------------------------------------------------------------------
    -- tile_is_in_map
    -- -----------------------------------------------------------------------

    describe("tile_is_in_map", function()
        it("should return true for tile inside bounds", function()
            local map = make_map()
            luassert.is_true(map:tile_is_in_map(point.of(0, 0)))
            luassert.is_true(map:tile_is_in_map(point.of(4, 4)))
            luassert.is_true(map:tile_is_in_map(point.of(2, 3)))
        end)

        it("should return false for tile outside bounds", function()
            local map = make_map()
            luassert.is_false(map:tile_is_in_map(point.of(-1, 0)))
            luassert.is_false(map:tile_is_in_map(point.of(0, -1)))
            luassert.is_false(map:tile_is_in_map(point.of(5, 0)))
            luassert.is_false(map:tile_is_in_map(point.of(0, 5)))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- get_tiles_by_label / tile_has_label / get_tiles_array_by_label
    -- -----------------------------------------------------------------------

    describe("get_tiles_by_label", function()
        it("should return empty table for unknown label", function()
            local map = make_map()
            local result = map:get_tiles_by_label("missing")
            luassert.are_equal(0, #result)
        end)

        it("should return the points for a known label", function()
            local p = point.of(1, 2)
            local map = battle_map.new(5, 5, { my_label = { p } })
            local result = map:get_tiles_by_label("my_label")
            luassert.are_equal(1, #result)
            luassert.are_equal(p, result[1])
        end)
    end)

    describe("tile_has_label", function()
        it("should return true when the tile carries the label", function()
            local p = point.of(2, 3)
            local map = battle_map.new(5, 5, { zone = { p } })
            luassert.is_true(map:tile_has_label(p, "zone"))
        end)

        it("should return false for a different tile", function()
            local p = point.of(2, 3)
            local map = battle_map.new(5, 5, { zone = { p } })
            luassert.is_false(map:tile_has_label(point.of(0, 0), "zone"))
        end)

        it("should return false for an unknown label", function()
            local p = point.of(2, 3)
            local map = battle_map.new(5, 5, {})
            luassert.is_false(map:tile_has_label(p, "zone"))
        end)
    end)

    describe("get_tiles_array_by_label", function()
        it("should mark labeled tiles as true", function()
            local p1 = point.of(1, 0)
            local p2 = point.of(3, 2)
            local map = battle_map.new(5, 5, { zone = { p1, p2 } })
            local arr = map:get_tiles_array_by_label("zone")
            luassert.is_true(arr:get_point(p1))
            luassert.is_true(arr:get_point(p2))
        end)

        it("should leave unlabeled tiles as false", function()
            local map = battle_map.new(5, 5, { zone = { point.of(1, 0) } })
            local arr = map:get_tiles_array_by_label("zone")
            luassert.is_false(arr:get_point(point.of(0, 0)))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- spawn_unit / get_unit_by_id / get_at_tile
    -- -----------------------------------------------------------------------

    describe("spawn_unit", function()
        it("should make the unit retrievable by id", function()
            local map = make_map()
            local unit = make_unit(1, point.of(0, 0))
            map:spawn_unit(unit, point.of(0, 0))
            luassert.are_equal(unit, map:get_unit_by_id(1))
        end)

        it("should make the unit retrievable by tile", function()
            local map = make_map()
            local tile = point.of(2, 3)
            local unit = make_unit(1, tile)
            map:spawn_unit(unit, tile)
            luassert.are_equal(unit, map:get_at_tile(tile))
        end)

        it("should error when the tile is already occupied", function()
            local map = make_map()
            local tile = point.of(1, 1)
            map:spawn_unit(make_unit(1, tile), tile)
            luassert.has_error(function()
                map:spawn_unit(make_unit(2, tile), tile)
            end)
        end)
    end)

    describe("get_at_tile", function()
        it("should return nil for out-of-bounds tiles", function()
            local map = make_map()
            luassert.is_nil(map:get_at_tile(point.of(-1, 0)))
        end)

        it("should return nil for an empty tile", function()
            local map = make_map()
            luassert.is_nil(map:get_at_tile(point.of(0, 0)))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- remove_unit
    -- -----------------------------------------------------------------------

    describe("remove_unit", function()
        it("should remove the unit from both lookups", function()
            local map = make_map()
            local tile = point.of(1, 1)
            local unit = make_unit(7, tile)
            map:spawn_unit(unit, tile)
            map:remove_unit(7)
            luassert.is_nil(map:get_unit_by_id(7))
            luassert.is_nil(map:get_at_tile(tile))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- tile_is_legal_destination
    -- -----------------------------------------------------------------------

    describe("tile_is_legal_destination", function()
        it("should return true for an empty tile", function()
            local map = make_map()
            local unit = make_unit(1, point.of(0, 0))
            map:spawn_unit(unit, point.of(0, 0))
            luassert.is_true(map:tile_is_legal_destination(unit, point.of(2, 2)))
        end)

        it("should return true when the tile is occupied by the same unit", function()
            local map = make_map()
            local tile = point.of(1, 1)
            local unit = make_unit(1, tile)
            map:spawn_unit(unit, tile)
            luassert.is_true(map:tile_is_legal_destination(unit, tile))
        end)

        it("should return false when occupied by a different unit", function()
            local map = make_map()
            local tile = point.of(1, 1)
            local unit_a = make_unit(1, point.of(0, 0))
            local unit_b = make_unit(2, tile)
            map:spawn_unit(unit_a, point.of(0, 0))
            map:spawn_unit(unit_b, tile)
            luassert.is_false(map:tile_is_legal_destination(unit_a, tile))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- move_unit
    -- -----------------------------------------------------------------------

    describe("move_unit", function()
        it("should update the unit's tile field", function()
            local map = make_map()
            local start = point.of(0, 0)
            local dest = point.of(2, 2)
            local unit = make_unit(1, start)
            map:spawn_unit(unit, start)
            map:move_unit(unit, dest)
            luassert.are_equal(dest, unit.tile)
        end)

        it("should clear the old tile and set the new tile", function()
            local map = make_map()
            local start = point.of(0, 0)
            local dest = point.of(2, 2)
            local unit = make_unit(1, start)
            map:spawn_unit(unit, start)
            map:move_unit(unit, dest)
            luassert.is_nil(map:get_at_tile(start))
            luassert.are_equal(unit, map:get_at_tile(dest))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- swap_tile_units
    -- -----------------------------------------------------------------------

    describe("swap_tile_units", function()
        it("should exchange two units between their tiles", function()
            local map = make_map()
            local tile_a = point.of(0, 0)
            local tile_b = point.of(2, 2)
            local unit_a = make_unit(1, tile_a)
            local unit_b = make_unit(2, tile_b)
            map:spawn_unit(unit_a, tile_a)
            map:spawn_unit(unit_b, tile_b)
            map:swap_tile_units(tile_a, tile_b)
            luassert.are_equal(unit_a, map:get_at_tile(tile_b))
            luassert.are_equal(unit_b, map:get_at_tile(tile_a))
            luassert.are_equal(tile_b, unit_a.tile)
            luassert.are_equal(tile_a, unit_b.tile)
        end)

        it("should work when one tile is empty", function()
            local map = make_map()
            local tile_a = point.of(0, 0)
            local tile_b = point.of(2, 2)
            local unit_a = make_unit(1, tile_a)
            map:spawn_unit(unit_a, tile_a)
            map:swap_tile_units(tile_a, tile_b)
            luassert.is_nil(map:get_at_tile(tile_a))
            luassert.are_equal(unit_a, map:get_at_tile(tile_b))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- kill_unit
    -- -----------------------------------------------------------------------

    describe("kill_unit", function()
        it("should add the unit to dead_units", function()
            local map = make_map()
            local tile = point.of(0, 0)
            local unit = make_unit(1, tile)
            map:spawn_unit(unit, tile)
            map:kill_unit(unit)
            luassert.are_equal(1, #map.dead_units)
            luassert.are_equal(unit, map.dead_units[1])
        end)

        it("should remove the unit from active lookups", function()
            local map = make_map()
            local tile = point.of(0, 0)
            local unit = make_unit(1, tile)
            map:spawn_unit(unit, tile)
            map:kill_unit(unit)
            luassert.is_nil(map:get_unit_by_id(1))
            luassert.is_nil(map:get_at_tile(tile))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- get_units / get_all_units / get_dead_units
    -- -----------------------------------------------------------------------

    describe("get_all_units", function()
        it("should return all active units", function()
            local map = make_map()
            map:spawn_unit(make_unit(1, point.of(0, 0)), point.of(0, 0))
            map:spawn_unit(make_unit(2, point.of(1, 0)), point.of(1, 0))
            local all = map:get_all_units()
            luassert.are_equal(2, #all)
        end)

        it("should return empty table when no units are present", function()
            local map = make_map()
            luassert.are_equal(0, #map:get_all_units())
        end)
    end)

    describe("get_units", function()
        it("should filter units by predicate", function()
            local map = make_map()
            map:spawn_unit(make_unit(1, point.of(0, 0), "player"), point.of(0, 0))
            map:spawn_unit(make_unit(2, point.of(1, 0), "enemy"),  point.of(1, 0))
            local enemies = map:get_units(function(u) return u.side == "enemy" end)
            luassert.are_equal(1, #enemies)
            luassert.are_equal(2, enemies[1].id)
        end)
    end)

    describe("get_dead_units", function()
        it("should return dead units matching the filter", function()
            local map = make_map()
            local tile = point.of(0, 0)
            local unit = make_unit(1, tile, "enemy")
            map:spawn_unit(unit, tile)
            map:kill_unit(unit)
            local dead_enemies = map:get_dead_units(function(u) return u.side == "enemy" end)
            luassert.are_equal(1, #dead_enemies)
        end)

        it("should exclude dead units that do not match the filter", function()
            local map = make_map()
            local tile = point.of(0, 0)
            local unit = make_unit(1, tile, "player")
            map:spawn_unit(unit, tile)
            map:kill_unit(unit)
            local dead_enemies = map:get_dead_units(function(u) return u.side == "enemy" end)
            luassert.are_equal(0, #dead_enemies)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- tile_has_distance_from_tile
    -- -----------------------------------------------------------------------

    describe("tile_has_distance_from_tile", function()
        it("should return true when distance equals min", function()
            local map = make_map()
            luassert.is_true(map:tile_has_distance_from_tile(
                point.of(0, 0), point.of(2, 0), 2))
        end)

        it("should return false when distance is less than min", function()
            local map = make_map()
            luassert.is_false(map:tile_has_distance_from_tile(
                point.of(0, 0), point.of(1, 0), 2))
        end)

        it("should support a range when max_distance is provided", function()
            local map = make_map()
            luassert.is_true(map:tile_has_distance_from_tile(
                point.of(0, 0), point.of(2, 0), 1, 3))
            luassert.is_false(map:tile_has_distance_from_tile(
                point.of(0, 0), point.of(4, 0), 1, 3))
        end)
    end)

    -- -----------------------------------------------------------------------
    -- get_terrain
    -- -----------------------------------------------------------------------

    describe("get_terrain", function()
        it("should return nil when the ground sprite is 0", function()
            local map = make_map()
            map.layers = make_layers(5, 5)
            -- default MockUserdata is all zeros
            luassert.is_nil(map:get_terrain(point.of(0, 0)))
        end)

        it("should return terrain data for a non-zero ground sprite", function()
            local map = make_map()
            local layers = make_layers(5, 5)
            -- set column 0, row 0 to sprite 1 using the mock's column-set API
            layers.terrain.ground:set(0, 1)
            map.layers = layers
            -- fget returns 0 by default → terrain index 0 → movement_cost=1, solid=false
            local result = map:get_terrain(point.of(0, 0))
            luassert.is_not_nil(result)
            luassert.are_equal(1, result.movement_cost)
            luassert.is_false(result.solid)
        end)

        it("should return solid=true when ground sprite has the solid flag (0x1)", function()
            local original_fget = _G.fget
            local map = make_map()
            local layers = make_layers(5, 5)
            layers.terrain.ground:set(0, 1)
            map.layers = layers
            _G.fget = function(_) return 0x1 end
            local result = map:get_terrain(point.of(0, 0))
            _G.fget = original_fget
            luassert.is_true(result.solid)
        end)

        it("should decode terrain index from flags to pick movement_cost", function()
            -- flags = 0xD (1101): solid=1, terrain=(0xD>>1)=6 → movement_cost=5
            local original_fget = _G.fget
            local map = make_map()
            local layers = make_layers(5, 5)
            layers.terrain.ground:set(0, 1)
            map.layers = layers
            _G.fget = function(_) return 0xD end
            local result = map:get_terrain(point.of(0, 0))
            _G.fget = original_fget
            luassert.is_true(result.solid)
            luassert.are_equal(5, result.movement_cost)
        end)
    end)

end)
