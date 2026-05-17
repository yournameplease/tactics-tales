local luassert = require("luassert")

local chunk_variants = require("src.tactics.battle.map.procgen.chunk_variants")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

---@param overrides table
---@return ChunkRecord
local function make_chunk(overrides)
    local base = {
        name   = "test",
        width  = 3,
        height = 3,
        tags   = {},
        rows   = {
            "#####",
            "#...#",
            "#...#",
            "#...#",
            "#####",
        },
        exits  = { north = nil, south = nil, east = nil, west = nil },
    }
    for k, v in pairs(overrides) do base[k] = v end
    return base
end

--- 5×5 asymmetric chunk (spawn glyph at top-left interior).
---@return ChunkRecord
local function asymmetric_chunk()
    return make_chunk({
        rows = {
            "#####",
            "#i..#",
            "#...#",
            "#...#",
            "#####",
        },
    })
end

--- 5×5 chunk with a north exit at columns 2-4.
---@return ChunkRecord
local function chunk_with_north_exit()
    return make_chunk({
        rows = {
            "#^^^#",
            "#...#",
            "#...#",
            "#...#",
            "#####",
        },
        exits = { north = { min = 2, max = 4 }, south = nil, east = nil, west = nil },
    })
end

--- 5×5 chunk with an east exit at rows 2-4.
---@return ChunkRecord
local function chunk_with_east_exit()
    return make_chunk({
        rows = {
            "#####",
            "#..>#",
            "#..>#",
            "#..>#",
            "#####",
        },
        exits = { north = nil, south = nil, east = { min = 2, max = 4 }, west = nil },
    })
end

--- 7×5 chunk (interior 5×3) with north exit at cols 3-5.
--- Used to verify dimension swapping on rotation.
---@return ChunkRecord
local function wide_chunk()
    return make_chunk({
        name   = "wide",
        width  = 5,
        height = 3,
        rows   = {
            "##^^^##",
            "#.....#",
            "#.....#",
            "#.....#",
            "#######",
        },
        exits = { north = { min = 3, max = 5 }, south = nil, east = nil, west = nil },
    })
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.battle.map.procgen.chunk_variants", function()
    describe("expand", function()
        -- AC #1 --
        it("returns the original chunk when no transformation tags are present", function()
            local chunk = make_chunk({ name = "plain" })
            local result = chunk_variants.expand({ chunk })
            luassert.are_equal(1, #result)
            luassert.are_equal("plain", result[1].name)
            luassert.are_same(chunk.rows, result[1].rows)
        end)

        -- AC #7 --
        it("names the rot90 variant with the base|rot90 convention", function()
            local chunk = asymmetric_chunk()
            chunk.name = "room"
            chunk.tags = { "rotate_90" }
            local result = chunk_variants.expand({ chunk })
            local names = {}
            for _, v in ipairs(result) do names[v.name] = true end
            luassert.is_true(names["room"])
            luassert.is_true(names["room|rot90"])
            luassert.is_true(names["room|rot180"])
            luassert.is_true(names["room|rot270"])
        end)

        -- AC #2: asymmetric chunk + rotate_90 → 4 variants --
        it("produces 4 rotational variants for an asymmetric chunk with rotate_90", function()
            local chunk = asymmetric_chunk()
            chunk.tags = { "rotate_90" }
            local result = chunk_variants.expand({ chunk })
            luassert.are_equal(4, #result)
        end)

        -- AC #2: non-square chunk dimensions swap on 90°/270° --
        it("swaps width and height on 90- and 270-degree rotations of a non-square chunk", function()
            local chunk = wide_chunk()
            chunk.tags = { "rotate_90" }
            local result = chunk_variants.expand({ chunk })
            local by_name = {}
            for _, v in ipairs(result) do by_name[v.name] = v end

            -- original: interior 5×3
            luassert.are_equal(5, by_name["wide"].width)
            luassert.are_equal(3, by_name["wide"].height)
            -- rot90: interior 3×5
            luassert.are_equal(3, by_name["wide|rot90"].width)
            luassert.are_equal(5, by_name["wide|rot90"].height)
            -- rot180: back to 5×3
            luassert.are_equal(5, by_name["wide|rot180"].width)
            luassert.are_equal(3, by_name["wide|rot180"].height)
            -- rot270: 3×5
            luassert.are_equal(3, by_name["wide|rot270"].width)
            luassert.are_equal(5, by_name["wide|rot270"].height)
        end)

        -- AC #4: north exit → east after rot90 --
        it("remaps north exit to east face after a rot90 rotation", function()
            local chunk = chunk_with_north_exit()
            chunk.tags = { "rotate_90" }
            local result = chunk_variants.expand({ chunk })
            local by_name = {}
            for _, v in ipairs(result) do by_name[v.name] = v end

            local rot90 = by_name["test|rot90"]
            luassert.is_nil(rot90.exits.north)
            luassert.are_same({ min = 2, max = 4 }, rot90.exits.east)
        end)

        -- AC #4: east exit → south (with range reversal) after rot90 --
        it("remaps east exit to south face with reversed range after rot90", function()
            local chunk = chunk_with_east_exit()
            chunk.tags = { "rotate_90" }
            local result = chunk_variants.expand({ chunk })
            local by_name = {}
            for _, v in ipairs(result) do by_name[v.name] = v end

            local rot90 = by_name["test|rot90"]
            -- east face had rows 2-4 (H=5). south gets cols 5+1-4 to 5+1-2 = [2,4] (still same for symmetric range)
            luassert.is_nil(rot90.exits.east)
            luassert.are_same({ min = 2, max = 4 }, rot90.exits.south)
        end)

        -- AC #4: flip_h reverses north range and swaps east↔west --
        it("reverses north range and swaps east/west exits on flip_h", function()
            local chunk = chunk_with_north_exit() -- north = {min=2, max=4}, face width=5
            chunk.tags = { "flip_h" }
            local result = chunk_variants.expand({ chunk })
            local by_name = {}
            for _, v in ipairs(result) do by_name[v.name] = v end

            local flipped = by_name["test|flip_h"]
            -- [2,4] on face width 5 → [5-4+1, 5-2+1] = [2, 4] (symmetric — same)
            luassert.are_same({ min = 2, max = 4 }, flipped.exits.north)
            luassert.is_nil(flipped.exits.east)
            luassert.is_nil(flipped.exits.west)
        end)

        it("reverses north range correctly for an asymmetric exit on flip_h", function()
            local chunk = make_chunk({
                rows = {
                    "#^^##",
                    "#...#",
                    "#...#",
                    "#...#",
                    "#####",
                },
                exits = { north = { min = 2, max = 3 }, south = nil, east = nil, west = nil },
                tags  = { "flip_h" },
            })
            local result = chunk_variants.expand({ chunk })
            local by_name = {}
            for _, v in ipairs(result) do by_name[v.name] = v end

            local flipped = by_name["test|flip_h"]
            -- [2,3] on face width 5 → [5-3+1, 5-2+1] = [3, 4]
            luassert.are_same({ min = 3, max = 4 }, flipped.exits.north)
        end)

        -- AC #3: flip_h + flip_v generates rot180 through group closure --
        it("generates rot180 variant from flip_h+flip_v tags (group closure)", function()
            local chunk = asymmetric_chunk()
            chunk.tags = { "flip_h", "flip_v" }
            local result = chunk_variants.expand({ chunk })
            luassert.are_equal(4, #result)
            local names = {}
            for _, v in ipairs(result) do names[v.name] = true end
            luassert.is_true(names["test"])
            luassert.is_true(names["test|flip_h"])
            luassert.is_true(names["test|flip_v"])
            luassert.is_true(names["test|rot180"])
        end)

        -- AC #5: spawn glyphs repositioned --
        it("repositions interior glyphs correctly under rot90", function()
            local chunk = make_chunk({
                name = "spawner",
                tags = { "rotate_90" },
                rows = {
                    "#####",
                    "#i..#",
                    "#...#",
                    "#...#",
                    "#####",
                },
            })
            local result = chunk_variants.expand({ chunk })
            local by_name = {}
            for _, v in ipairs(result) do by_name[v.name] = v end

            -- Original: `i` at row=2, col=2 (1-indexed).
            -- After CW rot90: new[r][c] = old[H+1-c][r] where H=5, W=5.
            -- i is at old (2, 2). New position: (x=2, H+1-y=5+1-2=4) = row 2, col 4.
            -- So in rot90, row 2 should have `i` at col 4: "#..i#"
            luassert.are_equal("#..i#", by_name["spawner|rot90"].rows[2])
        end)

        -- AC #6: tile-identical variants are deduplicated --
        it("deduplicates tile-identical variants for a symmetric chunk", function()
            -- All-dot interior is 4-fold symmetric under rotation.
            local chunk = make_chunk({ tags = { "rotate_90" } })
            local result = chunk_variants.expand({ chunk })
            luassert.are_equal(1, #result)
        end)

        -- AC #1: multiple input chunks, each expanded independently --
        it("expands multiple input chunks and returns a flat list", function()
            local c1 = make_chunk({ name = "a", tags = {} })
            local c2 = make_chunk({ name = "b", tags = { "rotate_90" } })
            local result = chunk_variants.expand({ c1, c2 })
            -- c1 → 1, c2 → 4 (all symmetric so all dedup to 1... wait, they're all the same rows)
            -- c2 is symmetric so also 1 variant
            luassert.are_equal(2, #result)
        end)

        -- AC: transformation tags stripped from derived variants --
        it("strips transformation tags from derived variants", function()
            local chunk = make_chunk({
                name = "room",
                tags = { "rotate_90", "deployment" },
                rows = {
                    "#####",
                    "#.d.#",
                    "#...#",
                    "#...#",
                    "#####",
                },
            })
            local result = chunk_variants.expand({ chunk })
            local by_name = {}
            for _, v in ipairs(result) do by_name[v.name] = v end

            -- rot90 variant should not have rotate_90 tag but should keep deployment
            local rot90_tags = by_name["room|rot90"].tags
            local has_rotate_90 = false
            local has_deployment = false
            for _, t in ipairs(rot90_tags) do
                if t == "rotate_90" then has_rotate_90 = true end
                if t == "deployment" then has_deployment = true end
            end
            luassert.is_false(has_rotate_90)
            luassert.is_true(has_deployment)
        end)
    end)
end)
