local luassert = require("luassert")
local map_generator = require("src.tactics.battle.map.map_generator")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local BASE_METATILE = 0x400

--- Build a minimal fetch result with all required layers backed by real
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

--- Install a temporary fetch override that returns `result`.
--- Returns a cleanup function that restores the original.
---@param result table
---@return fun()
local function stub_fetch(result)
    local original = _G.fetch
    ---@diagnostic disable-next-line: duplicate-set-field
    _G.fetch = function(_) return result end
    return function() _G.fetch = original end
end

--- Install a temporary include override that returns `result`.
---@param result table
---@return fun()
local function stub_include(result)
    local original = _G.include
    _G.include = function(_) return result end --[[@diagnostic disable-line: duplicate-set-field]]
    return function() _G.include = original end
end

--- Build a minimal Tiled map data structure.
---@param w integer Map width in tiles.
---@param h integer Map height in tiles.
---@param layers table[] Array of layer tables to include.
---@return table
local function make_tiled_map(w, h, layers)
    return {
        width = w,
        height = h,
        tilewidth = 16,
        tileheight = 16,
        tilesets = {
            { name = "my_tileset", firstgid = 1, filename = "my_tileset.tsx" }
        },
        layers = layers,
    }
end

--- Build a flat row-major tile-data array filled with a single tile ID.
---@param w integer
---@param h integer
---@param tile_id integer
---@return integer[]
local function make_tile_data(w, h, tile_id)
    local data = {}
    for i = 1, w * h do data[i] = tile_id end
    return data
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

        it("should default base_tile_id to 0", function()
            local restore = stub_fetch(make_fetch_result(3, 3))
            local map = map_generator.load_map({ type = "static", file = "test.lua" }, {})
            restore()
            luassert.are_equal(0, map.base_tile_id)
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
            fetch_result[1].bmp:set(0, BASE_METATILE + 5) -- column 0, row 0 = 1029

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
            fetch_result[1].bmp:set(0, BASE_METATILE + 7) -- metatile 7 at (0,0)

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
    -- load_map — tiled
    -- -----------------------------------------------------------------------

    describe("load_map (tiled)", function()
        it("should create a BattleMap with dimensions from the tiled source", function()
            local tiled = make_tiled_map(5, 3, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 5,
                    height = 3,
                    data = make_tile_data(5, 3, 1)
                }
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 0 })
            restore()

            luassert.are_equal(5, map.width)
            luassert.are_equal(3, map.height)
        end)

        it("should convert tile IDs using base + (tile_id - firstgid)", function()
            -- gfx_registry maps stem -> base 10; firstgid = 1; tile_id = 3
            -- expected sprite = 10 + (3 - 1) = 12
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = { 3, 3, 3, 3 }
                }
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 10 })
            restore()

            luassert.are_equal(12, map.layers.terrain.ground:get(0, 0))
        end)

        it("should look up base sprite index from gfx_registry by filename stem", function()
            -- filename "my_tileset.tsx" -> stem "my_tileset" -> base 100
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = { 1, 1, 1, 1 }
                }
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 100 })
            restore()

            -- tile_id=1, firstgid=1, base=100 => sprite = 100 + 0 = 100
            luassert.are_equal(100, map.layers.terrain.ground:get(0, 0))
        end)

        it("should return 0 for empty tiles (tile_id == 0)", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = { 0, 0, 0, 0 }
                }
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 50 })
            restore()

            luassert.are_equal(0, map.layers.terrain.ground:get(0, 0))
        end)

        it("should produce nil for missing optional layers", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                }
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 0 })
            restore()

            luassert.is_nil(map.layers.metatiles)
            luassert.is_nil(map.layers.terrain.front_wall)
            luassert.is_nil(map.layers.terrain.mid_wall)
            luassert.is_nil(map.layers.terrain.back_wall)
            luassert.is_nil(map.layers.terrain.ceiling)
        end)

        it("should populate optional layers when present", function()
            local tiled = make_tiled_map(2, 2, {
                { type = "tilelayer", name = "ground",      width = 2, height = 2, data = make_tile_data(2, 2, 1) },
                { type = "tilelayer", name = "front_walls", width = 2, height = 2, data = make_tile_data(2, 2, 2) },
                { type = "tilelayer", name = "back_walls",  width = 2, height = 2, data = make_tile_data(2, 2, 3) },
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 0 })
            restore()

            luassert.is_not_nil(map.layers.terrain.front_wall)
            luassert.is_not_nil(map.layers.terrain.back_wall)
            luassert.is_nil(map.layers.terrain.mid_wall)
        end)

        it("should error when the ground layer is missing", function()
            local tiled = make_tiled_map(2, 2, {
                { type = "tilelayer", name = "front_walls", width = 2, height = 2, data = make_tile_data(2, 2, 1) }
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            luassert.has_error(function()
                map_generator.load_map(def, {}, { my_tileset = 0 })
            end)
            restore()
        end)

        it("should skip non-tilelayer entries (e.g. objectgroup)", function()
            local tiled = make_tiled_map(2, 2, {
                { type = "tilelayer",   name = "ground",     width = 2,   height = 2, data = make_tile_data(2, 2, 1) },
                { type = "objectgroup", name = "deployment", objects = {} },
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 0 })
            restore()

            luassert.is_not_nil(map.layers.terrain.ground)
        end)

        it("should initialise empty player and enemy spawner tables", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                }
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 0 })
            restore()

            luassert.are_same({}, map.metadata.player_spawners)
            luassert.are_same({}, map.metadata.enemy_spawners)
        end)

        it("should set base_tile_id from the first tileset's gfx_registry base", function()
            local tiled = make_tiled_map(2, 2, {
                { type = "tilelayer", name = "ground", width = 2, height = 2, data = make_tile_data(2, 2, 1) }
            })
            local restore = stub_include(tiled)

            local def = { type = "tiled", file = "maps/test_map" }
            local map = map_generator.load_map(def, {}, { my_tileset = 256 })
            restore()

            luassert.are_equal(256, map.base_tile_id)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- load_map — spawn_groups
    -- -----------------------------------------------------------------------

    describe("load_map spawn_groups (tiled)", function()
        local function make_point_obj(x, y, props)
            return { shape = "point", x = x, y = y, properties = props or {} }
        end

        it("should produce an empty spawn_groups table when no object layers exist", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                }
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()
            luassert.are_same({}, map.spawn_groups)
        end)

        it("should create a group keyed by layer name with pixel coords converted to tile coords", function()
            -- tilewidth=16, tileheight=16; pixel (32,48) -> tile (2,3)
            local tiled = make_tiled_map(4, 4, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 4,
                    height = 4,
                    data = make_tile_data(4, 4, 1)
                },
                {
                    type = "objectgroup",
                    name = "spawn_zone",
                    properties = {},
                    objects = { make_point_obj(32, 48) }
                },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()
            luassert.is_not_nil(map.spawn_groups["spawn_zone"])
            luassert.are_equal(1, #map.spawn_groups["spawn_zone"].points)
            luassert.are_equal(2, map.spawn_groups["spawn_zone"].points[1].x)
            luassert.are_equal(3, map.spawn_groups["spawn_zone"].points[1].y)
        end)

        it("should default slot to 'default' when no slot property is present", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                },
                {
                    type = "objectgroup",
                    name = "squad",
                    properties = {},
                    objects = { make_point_obj(16, 16) }
                },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()
            luassert.are_equal("default", map.spawn_groups["squad"].points[1].slot)
        end)

        it("should attach per-object slot property to the point", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                },
                {
                    type = "objectgroup",
                    name = "squad",
                    properties = {},
                    objects = { make_point_obj(16, 16, { slot = "squad_leader" }) }
                },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()
            luassert.are_equal("squad_leader", map.spawn_groups["squad"].points[1].slot)
        end)

        it("should propagate layer-level slot to points that lack a per-object slot", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                },
                {
                    type = "objectgroup",
                    name = "boss_room",
                    properties = { slot = "boss", ai_hint = "stationary" },
                    objects = { make_point_obj(16, 16) }
                },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()
            luassert.are_equal("boss", map.spawn_groups["boss_room"].points[1].slot)
            luassert.are_equal("stationary", map.spawn_groups["boss_room"].points[1].ai_hint)
        end)

        it("should let per-object ai_hint override the layer default", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                },
                {
                    type = "objectgroup",
                    name = "patrol",
                    properties = { ai_hint = "patrol" },
                    objects = {
                        make_point_obj(16, 16),
                        make_point_obj(32, 16, { ai_hint = "stationary" }),
                    }
                },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()
            luassert.are_equal("patrol", map.spawn_groups["patrol"].points[1].ai_hint)
            luassert.are_equal("stationary", map.spawn_groups["patrol"].points[2].ai_hint)
        end)

        it("should attach per-layer 'from' to the group, not to individual points", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                },
                {
                    type = "objectgroup",
                    name = "reinforce",
                    properties = { from = "west" },
                    objects = { make_point_obj(0, 16), make_point_obj(0, 32) }
                },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()
            luassert.are_equal("west", map.spawn_groups["reinforce"].from)
            luassert.is_nil((map.spawn_groups["reinforce"].points[1] --[[@as any]]).from)
        end)

        it("should leave 'from' nil on groups that have no from property", function()
            local tiled = make_tiled_map(2, 2, {
                {
                    type = "tilelayer",
                    name = "ground",
                    width = 2,
                    height = 2,
                    data = make_tile_data(2, 2, 1)
                },
                {
                    type = "objectgroup",
                    name = "deploy",
                    properties = {},
                    objects = { make_point_obj(16, 16) }
                },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()
            luassert.is_nil(map.spawn_groups["deploy"].from)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- load_map — rect_zones
    -- -----------------------------------------------------------------------

    describe("load_map rect_zones (tiled)", function()
        local function make_rect_obj(x, y, w, h)
            return { shape = "rectangle", x = x, y = y, width = w, height = h }
        end

        it("should parse a rectangle object into tile-coord x, y, w, h", function()
            -- tilewidth=16, tileheight=16; pixel rect (32,48,64,32) -> tile (2,3,4,2)
            local tiled = make_tiled_map(8, 8, {
                { type = "tilelayer",   name = "ground",    width = 8, height = 8, data = make_tile_data(8, 8, 1) },
                { type = "objectgroup", name = "obj_zone",  objects = { make_rect_obj(32, 48, 64, 32) } },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()

            luassert.is_not_nil(map.rect_zones["obj_zone"])
            luassert.are_equal(2, map.rect_zones["obj_zone"].x)
            luassert.are_equal(3, map.rect_zones["obj_zone"].y)
            luassert.are_equal(4, map.rect_zones["obj_zone"].w)
            luassert.are_equal(2, map.rect_zones["obj_zone"].h)
        end)

        it("should not include a layer in rect_zones when it has no rectangles", function()
            local tiled = make_tiled_map(4, 4, {
                { type = "tilelayer",   name = "ground",   width = 4, height = 4, data = make_tile_data(4, 4, 1) },
                { type = "objectgroup", name = "pts_only", objects = {
                    { shape = "point", x = 16, y = 16, properties = {} }
                }},
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()

            luassert.is_nil(map.rect_zones["pts_only"])
        end)

        it("should produce an empty rect_zones table when no object layers exist", function()
            local tiled = make_tiled_map(2, 2, {
                { type = "tilelayer", name = "ground", width = 2, height = 2, data = make_tile_data(2, 2, 1) },
            })
            local restore = stub_include(tiled)
            local map = map_generator.load_map({ type = "tiled", file = "x" }, {}, {})
            restore()

            luassert.are_same({}, map.rect_zones)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- load_map — unknown type
    -- -----------------------------------------------------------------------

    describe("load_map (unknown type)", function()
        it("should error for an unrecognised map definition type", function()
            luassert.has_error(function()
                map_generator.load_map({ type = "unknown" --[[@as MapGenerationType]] }, {})
            end)
        end)
    end)

    -- -----------------------------------------------------------------------
    -- load_map — procgen type (AC#1, AC#2, AC#4)
    -- -----------------------------------------------------------------------

    describe("load_map (procgen type)", function()
        -- Fixture chunk pool covering all cell sizes used by the castle theme
        -- (both 3×3 and 2×2 grid shapes), each with deployment, open, boss_room,
        -- and escape_zone variants.
        local FIXTURE_CHUNKS = table.concat({
            "[deploy_3x3]", "deployment", "5 5",
            "#^^^#", "<ddd>", "<ddd>", "<ddd>", "#vvv#", "",
            "[open_3x3]", "5 5",
            "#^^^#", "<...>", "<...>", "<...>", "#vvv#", "",
            "[boss_3x3]", "boss_room", "5 5",
            "#^^^#", "<...>", "<...>", "<...>", "#vvv#", "",
            "[escape_3x3]", "escape_zone", "5 5",
            "#^^^#", "<...>", "<...>", "<...>", "#vvv#", "",
            "[deploy_4x3]", "deployment", "6 5",
            "#^^^^#", "<dddd>", "<dddd>", "<dddd>", "#vvvv#", "",
            "[open_4x3]", "6 5",
            "#^^^^#", "<....>", "<....>", "<....>", "#vvvv#", "",
            "[boss_4x3]", "boss_room", "6 5",
            "#^^^^#", "<....>", "<....>", "<....>", "#vvvv#", "",
            "[escape_4x3]", "escape_zone", "6 5",
            "#^^^^#", "<....>", "<....>", "<....>", "#vvvv#", "",
            "[deploy_3x4]", "deployment", "5 6",
            "#^^^#", "<ddd>", "<ddd>", "<ddd>", "<ddd>", "#vvv#", "",
            "[open_3x4]", "5 6",
            "#^^^#", "<...>", "<...>", "<...>", "<...>", "#vvv#", "",
            "[boss_3x4]", "boss_room", "5 6",
            "#^^^#", "<...>", "<...>", "<...>", "<...>", "#vvv#", "",
            "[escape_3x4]", "escape_zone", "5 6",
            "#^^^#", "<...>", "<...>", "<...>", "<...>", "#vvv#", "",
            "[deploy_4x4]", "deployment", "6 6",
            "#^^^^#", "<dddd>", "<dddd>", "<dddd>", "<dddd>", "#vvvv#", "",
            "[open_4x4]", "6 6",
            "#^^^^#", "<....>", "<....>", "<....>", "<....>", "#vvvv#", "",
            "[boss_4x4]", "boss_room", "6 6",
            "#^^^^#", "<....>", "<....>", "<....>", "<....>", "#vvvv#", "",
            "[escape_4x4]", "escape_zone", "6 6",
            "#^^^^#", "<....>", "<....>", "<....>", "<....>", "#vvvv#", "",
            "[deploy_6x6]", "deployment", "8 8",
            "#^^^^^^#", "<dddddd>", "<dddddd>", "<dddddd>",
            "<dddddd>", "<dddddd>", "<dddddd>", "#vvvvvv#", "",
            "[open_6x6]", "8 8",
            "#^^^^^^#", "<......>", "<......>", "<......>",
            "<......>", "<......>", "<......>", "#vvvvvv#", "",
            "[boss_6x6]", "boss_room", "8 8",
            "#^^^^^^#", "<......>", "<......>", "<......>",
            "<......>", "<......>", "<......>", "#vvvvvv#", "",
            "[escape_6x6]", "escape_zone", "8 8",
            "#^^^^^^#", "<......>", "<......>", "<......>",
            "<......>", "<......>", "<......>", "#vvvvvv#",
        }, "\n")

        local function stub_fetch_chunks()
            local original = _G.fetch
            _G.fetch = function(_) return FIXTURE_CHUNKS end
            return function() _G.fetch = original end
        end

        local function ground_snapshot(map)
            local g = map.layers.terrain.ground
            local t = {}
            for y = 0, 15 do
                for x = 0, 15 do
                    table.insert(t, g:get(x, y))
                end
            end
            return t
        end

        local DEF = { type = "procgen", theme = "castle", chunks = "fixture.chunks" }

        it("returns a BattleMap with 16×16 dimensions (AC#1)", function()
            local restore = stub_fetch_chunks()
            local map = map_generator.load_map(DEF, {}, {}, 1)
            restore()
            luassert.are_equal(16, map.width)
            luassert.are_equal(16, map.height)
        end)

        it("returned map has a ground terrain layer (AC#1)", function()
            local restore = stub_fetch_chunks()
            local map = map_generator.load_map(DEF, {}, {}, 1)
            restore()
            luassert.is_not_nil(map.layers)
            luassert.is_not_nil(map.layers.terrain)
            luassert.is_not_nil(map.layers.terrain.ground)
        end)

        it("same seed produces a byte-identical ground layer (AC#2)", function()
            local restore = stub_fetch_chunks()
            local map1 = map_generator.load_map(DEF, {}, {}, 42)
            local map2 = map_generator.load_map(DEF, {}, {}, 42)
            restore()
            luassert.are_same(ground_snapshot(map1), ground_snapshot(map2))
        end)

        -- AC#4: kill_boss placement
        it("kill_boss map has deployment_cell != boss_cell and no escape_cell", function()
            local restore = stub_fetch_chunks()
            local def = { type = "procgen", theme = "castle", chunks = "fixture.chunks", objective = "kill_boss" }
            local map = map_generator.load_map(def, {}, {}, 1)
            restore()
            luassert.is_not_nil(map.procgen_placement)
            luassert.is_not_nil(map.procgen_placement.deployment_cell)
            luassert.is_not_nil(map.procgen_placement.boss_cell)
            luassert.are_not_equal(map.procgen_placement.deployment_cell, map.procgen_placement.boss_cell)
            luassert.is_nil(map.procgen_placement.escape_cell)
        end)

        -- AC#5: escape placement
        it("escape map has deployment_cell != escape_cell and no boss_cell", function()
            local restore = stub_fetch_chunks()
            local def = { type = "procgen", theme = "castle", chunks = "fixture.chunks", objective = "escape" }
            local map = map_generator.load_map(def, {}, {}, 1)
            restore()
            luassert.is_not_nil(map.procgen_placement)
            luassert.is_not_nil(map.procgen_placement.deployment_cell)
            luassert.is_not_nil(map.procgen_placement.escape_cell)
            luassert.are_not_equal(map.procgen_placement.deployment_cell, map.procgen_placement.escape_cell)
            luassert.is_nil(map.procgen_placement.boss_cell)
        end)

        -- AC#6: rout placement
        it("rout map has deployment_cell and no boss_cell or escape_cell", function()
            local restore = stub_fetch_chunks()
            local def = { type = "procgen", theme = "castle", chunks = "fixture.chunks", objective = "rout" }
            local map = map_generator.load_map(def, {}, {}, 1)
            restore()
            luassert.is_not_nil(map.procgen_placement)
            luassert.is_not_nil(map.procgen_placement.deployment_cell)
            luassert.is_nil(map.procgen_placement.boss_cell)
            luassert.is_nil(map.procgen_placement.escape_cell)
        end)
    end)
end)
