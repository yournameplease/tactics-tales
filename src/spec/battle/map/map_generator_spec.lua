local luassert = require("luassert")
local map_generator = require("src.tactics.battle.map.map_generator")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local BASE_METATILE = 0x400

--- Build a minimal pt.fetch result with all required layers backed by real
--- MockUserdata of size w×h.  All sprites default to 0.
---@param w integer
---@param h integer
---@return table
local function make_fetch_result(w, h)
    return {
        { name = "metatiles",   bmp = userdata("u8", w, h) },
        { name = "floor",       bmp = userdata("u8", w, h) },
        { name = "front_walls", bmp = userdata("u8", w, h) },
        { name = "mid_walls",   bmp = userdata("u8", w, h) },
        { name = "back_walls",  bmp = userdata("u8", w, h) },
    }
end

--- Install a temporary pt.fetch override that returns `result`.
--- Returns a cleanup function that restores the original.
---@param result table
---@return fun()
local function stub_fetch(result)
    local original = pt.fetch
    pt.fetch = function(_) return result end
    return function() pt.fetch = original end
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("battle.map.map_generator", function()

    -- -----------------------------------------------------------------------
    -- load_map — dimensions
    -- -----------------------------------------------------------------------

    describe("load_map (static)", function()
        it("should create a BattleMap with dimensions from the metatile layer", function()
            -- Square maps are required: apply_checkerboard loops x over height
            -- and y over width, so non-square maps exceed the mock data bounds.
            local fetch_result = make_fetch_result(4, 4)
            local restore = stub_fetch(fetch_result)

            local def = { type = "static", file = "test.lua" }
            local map = map_generator.load_map(def, {})
            restore()

            -- BattleMap width/height come from metatiles:width() and :height()
            luassert.are_equal(4, map.width)
            luassert.are_equal(4, map.height)
        end)

        it("should initialise empty player and enemy spawner tables", function()
            local restore = stub_fetch(make_fetch_result(3, 3))

            local def = { type = "static", file = "test.lua" }
            local map = map_generator.load_map(def, {})
            restore()

            luassert.is_not_nil(map.metadata)
            luassert.are_same({}, map.metadata.player_spawners)
            luassert.are_same({}, map.metadata.enemy_spawners)
        end)

        it("should attach the loaded layers to the map", function()
            local restore = stub_fetch(make_fetch_result(3, 3))

            local def = { type = "static", file = "test.lua" }
            local map = map_generator.load_map(def, {})
            restore()

            luassert.is_not_nil(map.layers)
            luassert.is_not_nil(map.layers.terrain.ground)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- load_map — tile labels
    -- -----------------------------------------------------------------------

    describe("load_map label assignment", function()
        it("should label tiles whose metatile matches the definition", function()
            -- metatile index 5 → tile_labels["spawn"] = {5}
            -- Set metatiles(x=0, y=0) = BASE_METATILE + 5 = 1029
            -- Using mock set API: set(col, val_at_row0) sets data[row0][col]
            local fetch_result = make_fetch_result(4, 4)
            fetch_result[1].bmp:set(0, BASE_METATILE + 5)  -- column 0, row 0 = 1029

            local restore = stub_fetch(fetch_result)
            local def = { type = "static", file = "test.lua" }
            local map = map_generator.load_map(def, { spawn = { 5 } })
            restore()

            luassert.is_not_nil(map.tile_labels["spawn"])
            luassert.are_equal(1, #map.tile_labels["spawn"])
            luassert.are_equal(0, map.tile_labels["spawn"][1].x)
            luassert.are_equal(0, map.tile_labels["spawn"][1].y)
        end)

        it("should assign multiple labels from the same metatile", function()
            local fetch_result = make_fetch_result(4, 4)
            fetch_result[1].bmp:set(0, BASE_METATILE + 7)  -- metatile 7 at (0,0)

            local restore = stub_fetch(fetch_result)
            local def = { type = "static", file = "test.lua" }
            local map = map_generator.load_map(def, { zone_a = { 7 }, zone_b = { 7 } })
            restore()

            luassert.is_not_nil(map.tile_labels["zone_a"])
            luassert.is_not_nil(map.tile_labels["zone_b"])
            luassert.are_equal(1, #map.tile_labels["zone_a"])
            luassert.are_equal(1, #map.tile_labels["zone_b"])
        end)

        it("should not label tiles that do not match any metatile", function()
            -- metatile layer is all zeros; BASE_METATILE + 0 would be 1024,
            -- but 0 - BASE_METATILE = -1024 which is not in tile_labels
            local restore = stub_fetch(make_fetch_result(3, 3))
            local def = { type = "static", file = "test.lua" }
            local map = map_generator.load_map(def, { zone = { 5 } })
            restore()

            -- No tile in the default (all-zero) layer matches metatile 5
            luassert.is_nil(map.tile_labels["zone"])
        end)
    end)

    -- -----------------------------------------------------------------------
    -- load_map — unknown type
    -- -----------------------------------------------------------------------

    describe("load_map (unknown type)", function()
        it("should error for an unrecognised map definition type", function()
            local def = { type = "procgen", file = "test.lua" }
            luassert.has_error(function()
                map_generator.load_map(def, {})
            end)
        end)
    end)

end)
