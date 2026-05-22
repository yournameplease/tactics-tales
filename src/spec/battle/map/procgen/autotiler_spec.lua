require("src.spec.picotron_shim")

local luassert = require("luassert")

local autotiler = require("src.tactics.battle.map.procgen.autotiler")
local point     = require("src.tactics.util.point")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a 16-row glyph grid from a compact description.
--- Each element of `rows` is a string of exactly 16 characters.
--- Missing rows default to all '#'.
---@param rows table<integer, string>
---@return string[]
local function make_grid(rows)
    local g = {}
    for y = 1, 16 do
        g[y] = rows[y] or string.rep("#", 16)
    end
    return g
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.battle.map.procgen.autotiler", function()
    describe("build", function()
        -- AC#1 — dimensions and layer structure
        it("returns a BattleMap with width=16, height=16 (AC#1)", function()
            local rows = make_grid({})
            local map  = autotiler.build(rows)
            luassert.are_equal(16, map.width)
            luassert.are_equal(16, map.height)
        end)

        it("ground layer is populated (AC#1)", function()
            local rows = make_grid({ [1] = string.rep(".", 16) })
            local map  = autotiler.build(rows)
            luassert.is_not_nil(map.layers)
            luassert.is_not_nil(map.layers.terrain)
            luassert.is_not_nil(map.layers.terrain.ground)
        end)

        it("no other terrain layers are set (AC#1)", function()
            local rows = make_grid({})
            local map  = autotiler.build(rows)
            local terrain = map.layers.terrain
            luassert.is_nil(terrain.front_wall)
            luassert.is_nil(terrain.mid_wall)
            luassert.is_nil(terrain.back_wall)
            luassert.is_nil(terrain.ceiling)
            luassert.is_nil(map.layers.metatiles)
        end)

        it("spawn_groups is an empty table (AC#1)", function()
            local map = autotiler.build(make_grid({}))
            luassert.are_same({}, map.spawn_groups)
        end)

        it("rect_zones is an empty table (AC#1)", function()
            local map = autotiler.build(make_grid({}))
            luassert.are_same({}, map.rect_zones)
        end)

        -- AC#4 — tile placement for a hand-authored grid
        it("passable glyphs get tile id 1, walls get tile id 2 (AC#4)", function()
            -- 3-row hand-authored strip, padded to 16 wide and 16 tall.
            -- Row 1: all walls
            -- Row 2: '#' then 14 '.' then '#'
            -- Row 3: all walls
            local r2 = "#" .. string.rep(".", 14) .. "#"
            local rows = make_grid({
                [1] = string.rep("#", 16),
                [2] = r2,
                [3] = string.rep("#", 16),
            })
            local map = autotiler.build(rows)

            -- Row 1 (y=0): all tile id 2
            for x = 0, 15 do
                luassert.are_equal(2, map.layers.terrain.ground:get(x, 0),
                    "row 1 x=" .. x .. " should be wall (2)")
            end
            -- Row 2 (y=1): first and last are 2; middle 14 are 1
            luassert.are_equal(2, map.layers.terrain.ground:get(0, 1),  "r2 x=0 wall")
            luassert.are_equal(2, map.layers.terrain.ground:get(15, 1), "r2 x=15 wall")
            for x = 1, 14 do
                luassert.are_equal(1, map.layers.terrain.ground:get(x, 1),
                    "r2 x=" .. x .. " floor")
            end
        end)

        it("all passable glyph types map to tile id 1 (AC#4)", function()
            -- Row 1 contains each passable glyph once; rest are walls.
            local passable_glyphs = ". d i r t c p a"
            local chars = {}
            for c in passable_glyphs:gmatch("%S") do table.insert(chars, c) end
            -- Build a row: 9 passable chars + 7 walls = 16
            local row1 = table.concat(chars) .. string.rep("#", 7)
            luassert.are_equal(16, #row1)

            local rows = make_grid({ [1] = row1 })
            local map  = autotiler.build(rows)

            for idx, _ in ipairs(chars) do
                local x = idx - 1  -- 0-indexed
                luassert.are_equal(1, map.layers.terrain.ground:get(x, 0),
                    "glyph '" .. chars[idx] .. "' at x=" .. x .. " should be floor (1)")
            end
        end)

        -- AC#2 — tile_labels populated from spawn glyphs
        it("spawn glyphs produce expected tile labels (AC#2)", function()
            -- Row 1: i r t c d, rest walls.  Row 2+: all walls.
            local row1 = "irtcd" .. string.rep("#", 11)
            local rows = make_grid({ [1] = row1 })
            local map  = autotiler.build(rows)

            local labels = map.tile_labels
            luassert.are_equal(1, #labels.enemy_infantry,  "one infantry label")
            luassert.are_equal(1, #labels.enemy_ranged,    "one ranged label")
            luassert.are_equal(1, #labels.enemy_tank,      "one tank label")
            luassert.are_equal(1, #labels.enemy_commander, "one commander label")
            luassert.are_equal(1, #labels.player_deployment, "one deployment label")

            luassert.are_same(point.of(0, 0), labels.enemy_infantry[1])
            luassert.are_same(point.of(1, 0), labels.enemy_ranged[1])
            luassert.are_same(point.of(2, 0), labels.enemy_tank[1])
            luassert.are_same(point.of(3, 0), labels.enemy_commander[1])
            luassert.are_same(point.of(4, 0), labels.player_deployment[1])
        end)

        it("'t' glyph maps to enemy_tank label (AC#2)", function()
            local row1 = "t" .. string.rep("#", 15)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            luassert.are_equal(1, #map.tile_labels.enemy_tank)
            luassert.are_same(point.of(0, 0), map.tile_labels.enemy_tank[1])
            luassert.is_nil(map.tile_labels.enemy_commander)
        end)

        -- AC#3 — 'p' and 'a' produce no tile labels
        it("'p' and 'a' glyphs produce no tile labels (AC#3)", function()
            local row1 = "pa" .. string.rep("#", 14)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            luassert.is_nil(map.tile_labels.p)
            luassert.is_nil(map.tile_labels.a)
            -- Also confirm they are absent from all label lists
            for label, pts in pairs(map.tile_labels) do
                luassert.are_not_equal(0, #pts,
                    "label '" .. label .. "' should be absent or non-empty, never empty")
            end
        end)

        it("multiple spawn glyphs of the same type all appear in tile_labels (AC#2)", function()
            -- Two infantry glyphs at columns 0 and 2.
            local row1 = "i#i" .. string.rep("#", 13)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            luassert.are_equal(2, #map.tile_labels.enemy_infantry)
        end)

        it("'#' and '.' produce no tile labels (AC#4)", function()
            local row1 = string.rep(".", 8) .. string.rep("#", 8)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            luassert.are_same({}, map.tile_labels)
        end)

        -- Boss glyph tests
        it("uppercase 'G' maps to enemy_tank_boss tile label and renders as floor", function()
            local row1 = "G" .. string.rep("#", 15)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            luassert.are_equal(1, #map.tile_labels.enemy_tank_boss)
            luassert.are_same(point.of(0, 0), map.tile_labels.enemy_tank_boss[1])
            luassert.are_equal(1, map.layers.terrain.ground:get(0, 0), "G should be floor (1)")
        end)

        it("uppercase boss glyphs all map to correct labels and render as floor", function()
            local row1 = "IRGC" .. string.rep("#", 12)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            luassert.are_equal(1, #map.tile_labels.enemy_infantry_boss)
            luassert.are_equal(1, #map.tile_labels.enemy_ranged_boss)
            luassert.are_equal(1, #map.tile_labels.enemy_tank_boss)
            luassert.are_equal(1, #map.tile_labels.enemy_commander_boss)
            for x = 0, 3 do
                luassert.are_equal(1, map.layers.terrain.ground:get(x, 0),
                    "boss glyph at x=" .. x .. " should be floor (1)")
            end
        end)

        -- spawn_label_meta tests
        it("spawn_label_meta is populated for labels with tile positions", function()
            local row1 = "T" .. string.rep("#", 15)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            luassert.is_not_nil(map.spawn_label_meta)
            local meta = map.spawn_label_meta["enemy_tank_boss"]
            luassert.is_not_nil(meta)
            luassert.are_equal("enemy_tank", meta.role)
            luassert.are_same({ "boss" }, meta.tags)
        end)

        it("spawn_label_meta for normal glyphs has role and no tags", function()
            local row1 = "i" .. string.rep("#", 15)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            local meta = map.spawn_label_meta["enemy_infantry"]
            luassert.is_not_nil(meta)
            luassert.are_equal("enemy_infantry", meta.role)
            luassert.is_nil(meta.tags)
        end)

        it("spawn_label_meta only contains labels with at least one tile", function()
            local row1 = "i" .. string.rep("#", 15)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            luassert.is_nil(map.spawn_label_meta["enemy_tank_boss"])
            luassert.is_nil(map.spawn_label_meta["enemy_ranged"])
        end)

        it("spawn_label_meta player_deployment has role 'player'", function()
            local row1 = "d" .. string.rep("#", 15)
            local map  = autotiler.build(make_grid({ [1] = row1 }))
            local meta = map.spawn_label_meta["player_deployment"]
            luassert.is_not_nil(meta)
            luassert.are_equal("player", meta.role)
            luassert.is_nil(meta.tags)
        end)
    end)
end)
