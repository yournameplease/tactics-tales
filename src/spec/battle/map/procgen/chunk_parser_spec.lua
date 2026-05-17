require("src.spec.picotron_shim")

local luassert = require("luassert")

local chunk_parser = require("src.tactics.battle.map.procgen.chunk_parser")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Concatenate `lines` with newline separators.
---@param lines string[]
---@return string
local function chunks_text(lines)
    return table.concat(lines, "\n")
end

--- 5x5 wall ring with one interior tile of `interior` at the center.
--- Interior dimension 3x3 (minimum allowed).
---@param interior string Single character (e.g. ".", "d", "i").
---@return string[]
local function minimal_rows(interior)
    return {
        "#####",
        "#...#",
        "#." .. interior .. ".#",
        "#...#",
        "#####",
    }
end

describe("tactics.battle.map.procgen.chunk_parser", function()
    describe("parse", function()
        it("returns a single chunk with name, dimensions, and glyph rows", function()
            local text = chunks_text({
                "[room]",
                "5 5",
                "#####",
                "#...#",
                "#...#",
                "#...#",
                "#####",
            })

            local chunks = chunk_parser.parse(text)

            luassert.are_equal(1, #chunks)
            luassert.are_equal("room", chunks[1].name)
            luassert.are_equal(5, chunks[1].width)
            luassert.are_equal(5, chunks[1].height)
            luassert.are_same({
                "#####",
                "#...#",
                "#...#",
                "#...#",
                "#####",
            }, chunks[1].rows)
        end)

        it("parses multiple chunks separated by blank lines", function()
            local lines = { "[a]", "5 5" }
            for _, r in ipairs(minimal_rows(".")) do table.insert(lines, r) end
            table.insert(lines, "")
            table.insert(lines, "[b]")
            table.insert(lines, "5 5")
            for _, r in ipairs(minimal_rows(".")) do table.insert(lines, r) end

            local chunks = chunk_parser.parse(chunks_text(lines))

            luassert.are_equal(2, #chunks)
            luassert.are_equal("a", chunks[1].name)
            luassert.are_equal("b", chunks[2].name)
        end)

        it("captures tags from the optional tags line", function()
            local lines = { "[entry]", "deployment", "5 5" }
            for _, r in ipairs(minimal_rows("d")) do table.insert(lines, r) end

            local chunks = chunk_parser.parse(chunks_text(lines))

            luassert.are_same({ "deployment" }, chunks[1].tags)
        end)

        it("defaults tags to an empty list when the tags line is absent", function()
            local lines = { "[room]", "5 5" }
            for _, r in ipairs(minimal_rows(".")) do table.insert(lines, r) end

            local chunks = chunk_parser.parse(chunks_text(lines))

            luassert.are_same({}, chunks[1].tags)
        end)

        it("derives exit zones from contiguous directional runs on each face", function()
            local text = chunks_text({
                "[four_exits]",
                "5 5",
                "#^^^#",
                "<...>",
                "<...>",
                "<...>",
                "#vvv#",
            })

            local chunks = chunk_parser.parse(text)
            local exits = chunks[1].exits

            luassert.are_same({ min = 2, max = 4 }, exits.north)
            luassert.are_same({ min = 2, max = 4 }, exits.south)
            luassert.are_same({ min = 2, max = 4 }, exits.west)
            luassert.are_same({ min = 2, max = 4 }, exits.east)
        end)

        it("leaves a face's exit nil when no directional markers appear", function()
            local text = chunks_text({
                "[dead_end]",
                "5 5",
                "#####",
                "<...#",
                "<...#",
                "<...#",
                "#####",
            })

            local chunks = chunk_parser.parse(text)
            local exits = chunks[1].exits

            luassert.is_nil(exits.north)
            luassert.is_nil(exits.south)
            luassert.is_nil(exits.east)
            luassert.are_same({ min = 2, max = 4 }, exits.west)
        end)

        it("rejects a chunk whose corner is not #", function()
            local text = chunks_text({
                "[bad]",
                "5 5",
                ".####",
                "#...#",
                "#...#",
                "#...#",
                "#####",
            })

            luassert.has_error(function() chunk_parser.parse(text) end)
        end)

        it("rejects an invalid character in the border ring", function()
            local text = chunks_text({
                "[bad]",
                "5 5",
                "#^x^#",
                "<...>",
                "<...>",
                "<...>",
                "#vvv#",
            })

            luassert.has_error(function() chunk_parser.parse(text) end)
        end)

        it("rejects an invalid character in the interior", function()
            local lines = { "[bad]", "5 5" }
            for _, r in ipairs(minimal_rows("X")) do table.insert(lines, r) end

            luassert.has_error(function() chunk_parser.parse(chunks_text(lines)) end)
        end)

        it("rejects a directional marker on the wrong face", function()
            local text = chunks_text({
                "[bad]",
                "5 5",
                "#####",
                "v...#",
                "#...#",
                "#...#",
                "#####",
            })

            luassert.has_error(function() chunk_parser.parse(text) end)
        end)

        it("rejects a face with two contiguous directional runs (split exits)", function()
            local text = chunks_text({
                "[bad]",
                "7 5",
                "#^^#^^#",
                "<.....>",
                "<.....>",
                "<.....>",
                "##vvv##",
            })

            luassert.has_error(function() chunk_parser.parse(text) end)
        end)

        it("rejects duplicate chunk names within a file", function()
            local lines = { "[room]", "5 5" }
            for _, r in ipairs(minimal_rows(".")) do table.insert(lines, r) end
            table.insert(lines, "")
            table.insert(lines, "[room]")
            table.insert(lines, "5 5")
            for _, r in ipairs(minimal_rows(".")) do table.insert(lines, r) end

            luassert.has_error(function() chunk_parser.parse(chunks_text(lines)) end)
        end)

        it("rejects a chunk containing `d` without the deployment tag", function()
            local lines = { "[bad]", "5 5" }
            for _, r in ipairs(minimal_rows("d")) do table.insert(lines, r) end

            luassert.has_error(function() chunk_parser.parse(chunks_text(lines)) end)
        end)

        it("rejects a chunk tagged `deployment` without a `d` glyph", function()
            local lines = { "[bad]", "deployment", "5 5" }
            for _, r in ipairs(minimal_rows(".")) do table.insert(lines, r) end

            luassert.has_error(function() chunk_parser.parse(chunks_text(lines)) end)
        end)

        it("rejects a chunk whose interior is smaller than 3 tiles on either axis", function()
            local text = chunks_text({
                "[tiny]",
                "4 4",
                "####",
                "#..#",
                "#..#",
                "####",
            })

            luassert.has_error(function() chunk_parser.parse(text) end)
        end)

        it("emits a log warning but parses successfully for unknown tags", function()
            local original_warn = log.warn
            local warnings = {}
            log.warn = function(...) table.insert(warnings, table.concat({ ... }, " ")) end
            finally(function() log.warn = original_warn end)

            local lines = { "[room]", "deployment future_unknown_tag", "5 5" }
            for _, r in ipairs(minimal_rows("d")) do table.insert(lines, r) end

            local chunks = chunk_parser.parse(chunks_text(lines))

            luassert.are_equal(1, #chunks)
            luassert.is_true(#warnings > 0)
        end)

        it("parses the spec §7.3 example into four valid chunks", function()
            local text = chunks_text({
                "-- castle.chunks",
                "-- Castle theme chunk definitions",
                "",
                "[gatehouse]",
                "deployment",
                "6 5",
                "#^^^^#",
                "<d...>",
                "<.d..>",
                "<...d>",
                "##vv##",
                "",
                "[corridor_ns]",
                "5 5",
                "#^^^#",
                "#...#",
                "#.i.#",
                "#...#",
                "#vvv#",
                "",
                "[corner_room]",
                "5 5",
                "#^^^#",
                "<...#",
                "<...#",
                "<...#",
                "#####",
                "",
                "[wide_hall]",
                "7 5",
                "#^^^^^#",
                "<.....>",
                "<..i..>",
                "<.....>",
                "##vvv##",
            })

            local chunks = chunk_parser.parse(text)
            luassert.are_equal(4, #chunks)
            luassert.are_equal("gatehouse", chunks[1].name)
            luassert.are_same({ "deployment" }, chunks[1].tags)
            luassert.are_equal("corridor_ns", chunks[2].name)
            luassert.are_equal("corner_room", chunks[3].name)
            luassert.are_equal("wide_hall", chunks[4].name)
            luassert.are_same({ min = 2, max = 6 }, chunks[4].exits.north)
        end)

        it("load_theme reads via fetch() and parses the result", function()
            local original_fetch = _G.fetch
            local requested
            _G.fetch = function(path) ---@diagnostic disable-line: duplicate-set-field
                requested = path
                return chunks_text({ "[room]", "5 5", table.unpack(minimal_rows(".")) })
            end
            finally(function() _G.fetch = original_fetch end)

            local chunks = chunk_parser.load_theme("mods/test/game_data/chunks/castle.chunks")

            luassert.are_equal("mods/test/game_data/chunks/castle.chunks", requested)
            luassert.are_equal(1, #chunks)
            luassert.are_equal("room", chunks[1].name)
        end)

        it("load_theme errors when fetch returns nil", function()
            local original_fetch = _G.fetch
            _G.fetch = function(_) return nil end ---@diagnostic disable-line: duplicate-set-field
            finally(function() _G.fetch = original_fetch end)

            luassert.has_error(function() chunk_parser.load_theme("missing.chunks") end)
        end)

        it("ignores comment lines starting with --", function()
            local lines = { "-- a comment", "[room]", "-- another comment", "5 5" }
            for _, r in ipairs(minimal_rows(".")) do table.insert(lines, r) end

            local chunks = chunk_parser.parse(chunks_text(lines))

            luassert.are_equal(1, #chunks)
            luassert.are_equal("room", chunks[1].name)
        end)
    end)
end)
