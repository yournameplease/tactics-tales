require("src.spec.picotron_shim")

local luassert = require("luassert")

local glyph_grid    = require("src.tactics.battle.map.procgen.glyph_grid")
local chunk_selector = require("src.tactics.battle.map.procgen.chunk_selector")
local graph_mod     = require("src.tactics.battle.map.procgen.graph")
local random        = require("src.tactics.util.random")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

-- Theme: wall=2, no grow, 2×2 grid with widths [7,7].
-- Budget check: 7 + 2 + 7 = 16. ✓ (zero surplus → zero border)
local function make_theme()
    return {
        wall_thickness       = 2,
        wall_grow_probability = 0,
        exit_width_weights   = { [1] = 1 },
        extra_edge_probability = 0,
    }
end

local function make_grid()
    return {
        col_widths = { 7, 7 }, row_heights = { 7, 7 },
        col_walls = { 2 }, row_walls = { 2 },
        border_left = 0, border_right = 0, border_top = 0, border_bottom = 0,
    }
end

--- All-exit 7×7 interior chunk (9×9 full grid).
---@param name string
---@param deployment boolean?
---@return ChunkRecord
local function make_chunk(name, deployment)
    local interior = deployment and "d" or "."
    local rows = {}
    rows[1] = "#^^^^^^^#"
    for i = 2, 8 do
        rows[i] = "<" .. string.rep(interior, 7) .. ">"
    end
    rows[9] = "#vvvvvvv#"
    return {
        name   = name,
        width  = 7,
        height = 7,
        tags   = deployment and { "deployment" } or {},
        rows   = rows,
        exits  = {
            north = { min = 2, max = 8 },
            south = { min = 2, max = 8 },
            east  = { min = 2, max = 8 },
            west  = { min = 2, max = 8 },
        },
    }
end

local function make_pool()
    return {
        make_chunk("normal_1"),
        make_chunk("normal_2"),
        make_chunk("deploy", true),
    }
end

-- Passable characters in the glyph vocabulary (everything except '#').
local PASSABLE = {
    ["."] = true, ["d"] = true, ["g"] = true,
    ["i"] = true, ["r"] = true, ["t"] = true,
    ["c"] = true, ["p"] = true, ["a"] = true,
}

local VALID_VOCAB = { ["#"] = true }
for k in pairs(PASSABLE) do VALID_VOCAB[k] = true end

--- Flood-fill from (sx, sy); return count of reachable tiles.
---@param rows string[]
---@param sx integer
---@param sy integer
---@return integer
local function flood_fill(rows, sx, sy)
    local seen = {}
    local function key(x, y) return y * 100 + x end
    local stack = { { sx, sy } }
    seen[key(sx, sy)] = true
    local count = 0
    while #stack > 0 do
        local pos = table.remove(stack)
        local x, y = pos[1], pos[2]
        if x >= 1 and x <= 16 and y >= 1 and y <= 16 then
            local c = rows[y]:sub(x, x)
            if PASSABLE[c] then
                count = count + 1
                for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
                    local nx, ny = x + d[1], y + d[2]
                    local k2 = key(nx, ny)
                    if not seen[k2] then
                        seen[k2] = true
                        table.insert(stack, { nx, ny })
                    end
                end
            end
        end
    end
    return count
end

--- Count all passable tiles in the grid.
---@param rows string[]
---@return integer
local function count_passable(rows)
    local n = 0
    for y = 1, 16 do
        for x = 1, 16 do
            if PASSABLE[rows[y]:sub(x, x)] then n = n + 1 end
        end
    end
    return n
end

--- Build gen_result from chunk_selector for a 2×2 spanning-tree graph.
---@param seed integer
---@return ChunkGenerationResult
---@return RngInstance  RNG advanced past chunk selection, ready for assemble
local function generate(seed)
    local theme = make_theme()
    local grid  = make_grid()
    local pool  = make_pool()
    local rng   = random.new(seed)
    local g     = graph_mod.generate(theme, 2, 2, rng)
    local sel, err = chunk_selector.select(grid, g, pool, rng, nil, { deployment_cell = 1 })
    assert(sel, "generate helper: chunk_selector.select failed: " .. tostring(err))
    return {
        assignment       = sel.assignment,
        deployment_cell  = sel.deployment_cell,
        graph            = g,
    }, rng
end

-- ---------------------------------------------------------------------------
-- Helpers for off-screen exit tests
-- ---------------------------------------------------------------------------

-- 2×2 grid with 1-tile borders on all sides.
-- Budget per axis: 1 (border) + 6 (cell) + 2 (wall) + 6 (cell) + 1 (border) = 16 ✓
local function make_bordered_grid()
    return {
        col_widths = { 6, 6 }, row_heights = { 6, 6 },
        col_walls = { 2 }, row_walls = { 2 },
        border_left = 1, border_right = 1,
        border_top = 1, border_bottom = 1,
    }
end

-- All-exit 6×6 interior chunk (8×8 full grid).
local function make_6x6_chunk(name, deployment)
    local interior = deployment and "d" or "."
    local rows = {}
    rows[1] = "#^^^^^^#"
    for i = 2, 7 do
        rows[i] = "<" .. string.rep(interior, 6) .. ">"
    end
    rows[8] = "#vvvvvv#"
    return {
        name   = name,
        width  = 6,
        height = 6,
        tags   = deployment and { "deployment" } or {},
        rows   = rows,
        exits  = {
            north = { min = 2, max = 7 },
            south = { min = 2, max = 7 },
            east  = { min = 2, max = 7 },
            west  = { min = 2, max = 7 },
        },
    }
end

--- Build gen_result for the bordered 2×2 grid.
---@param seed integer
---@param offscreen_edges table
---@return ChunkGenerationResult
---@return RngInstance
local function generate_bordered(seed, offscreen_edges)
    local theme = make_theme()
    local grid  = make_bordered_grid()
    local pool  = { make_6x6_chunk("normal"), make_6x6_chunk("deploy", true) }
    local rng   = random.new(seed)
    local g     = graph_mod.generate(theme, 2, 2, rng)
    local sel, err = chunk_selector.select(grid, g, pool, rng, offscreen_edges or {}, { deployment_cell = 1 })
    assert(sel, "generate_bordered: chunk_selector.select failed: " .. tostring(err))
    return {
        assignment      = sel.assignment,
        deployment_cell = sel.deployment_cell,
        graph           = g,
    }, rng
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.battle.map.procgen.glyph_grid", function()
    describe("assemble", function()
        it("returns exactly 16 rows each of length 16 (AC#1)", function()
            local gen_result, rng = generate(1)
            local assembled = glyph_grid.assemble(make_theme(), make_grid(), gen_result, {}, rng)
            local rows = assembled.rows

            luassert.are_equal(16, #rows)
            for y = 1, 16 do
                luassert.are_equal(16, #rows[y],
                    "row " .. y .. " has length " .. #rows[y])
            end
        end)

        it("every character is in the valid vocabulary (AC#1)", function()
            local gen_result, rng = generate(2)
            local assembled = glyph_grid.assemble(make_theme(), make_grid(), gen_result, {}, rng)
            local rows = assembled.rows

            for y = 1, 16 do
                for x = 1, 16 do
                    local c = rows[y]:sub(x, x)
                    luassert.is_true(VALID_VOCAB[c] ~= nil,
                        "invalid glyph '" .. c .. "' at (" .. x .. "," .. y .. ")")
                end
            end
        end)

        it("each connection has passable tiles in its wall gap (AC#2)", function()
            local theme = make_theme()
            local grid  = make_grid()
            local gen_result, rng = generate(3)
            local assembled = glyph_grid.assemble(theme, grid, gen_result, {}, rng)
            local rows = assembled.rows

            local grid_w = #grid.col_widths

            local function x_start(col)
                local x = grid.border_left + 1
                for c = 1, col - 1 do x = x + grid.col_widths[c] + grid.col_walls[c] end
                return x
            end
            local function y_start(row)
                local y = grid.border_top + 1
                for r = 1, row - 1 do y = y + grid.row_heights[r] + grid.row_walls[r] end
                return y
            end

            for _, e in ipairs(gen_result.graph.edges) do
                local a, b = e[1], e[2]
                local col_a = ((a - 1) % grid_w) + 1
                local row_a = math.floor((a - 1) / grid_w) + 1

                local passable_in_gap = false
                if b - a == grid_w then
                    -- Vertical edge: gap is rows between A's bottom and B's top.
                    local gap_y_lo = y_start(row_a) + grid.row_heights[row_a]
                    local gap_y_hi = y_start(row_a + 1) - 1
                    for y = gap_y_lo, gap_y_hi do
                        for x = x_start(col_a), x_start(col_a) + grid.col_widths[col_a] - 1 do
                            if PASSABLE[rows[y]:sub(x, x)] then passable_in_gap = true end
                        end
                    end
                else
                    -- Horizontal edge: gap is cols between A's right and B's left.
                    local gap_x_lo = x_start(col_a) + grid.col_widths[col_a]
                    local gap_x_hi = x_start(col_a + 1) - 1
                    for x = gap_x_lo, gap_x_hi do
                        for y = y_start(row_a), y_start(row_a) + grid.row_heights[row_a] - 1 do
                            if PASSABLE[rows[y]:sub(x, x)] then passable_in_gap = true end
                        end
                    end
                end

                luassert.is_true(passable_in_gap,
                    "no passable tile in wall gap for edge {" .. a .. "," .. b .. "}")
            end
        end)

        -- it("width-1 bridge connections have 'g' at their passage center (AC#3)", function()
        --     -- With exit_width_weights={[1]=1} and no extra edges, every connection is a
        --     -- width-1 bridge.  All 3 wall-gap centres in the 2×2 spanning tree must be 'g'.
        --     local theme       = make_theme()   -- extra_edge_prob=0, weights=[1]:1
        --     local grid        = make_grid()
        --     local gen_result, rng = generate(5)
        --     local assembled   = glyph_grid.assemble(theme, grid, gen_result, {}, rng)
        --     local rows        = assembled.rows

        --     local bridges     = graph_mod.bridges(gen_result.graph)
        --     luassert.is_true(#bridges > 0, "expected at least one bridge in spanning tree")

        --     -- For each bridge, verify 'g' at the passage center.
        --     -- With width=1 the center is the single carved tile in the middle of the gap.
        --     local grid_w = #grid.col_widths

        --     local function x_start(col)
        --         local x = grid.border_left + 1
        --         for c = 1, col - 1 do x = x + grid.col_widths[c] + grid.col_walls[c] end
        --         return x
        --     end
        --     local function y_start(row)
        --         local y = grid.border_top + 1
        --         for r = 1, row - 1 do y = y + grid.row_heights[r] + grid.row_walls[r] end
        --         return y
        --     end

        --     for _, e in ipairs(bridges) do
        --         local a, b   = e[1], e[2]
        --         local col_a  = ((a - 1) % grid_w) + 1
        --         local row_a  = math.floor((a - 1) / grid_w) + 1

        --         if b - a == grid_w then
        --             -- Vertical edge: gap in y; carved x is the exit position.
        --             -- Scan the gap rows for 'g'.
        --             local gap_y_lo = y_start(row_a) + grid.row_heights[row_a]
        --             local gap_y_hi = y_start(row_a + 1) - 1
        --             local mid_y    = gap_y_lo + math.floor((gap_y_hi - gap_y_lo) / 2)
        --             -- Find the single 'g' or non-'#' column in the gap at mid_y.
        --             local found_g = false
        --             for x = x_start(col_a), x_start(col_a) + grid.col_widths[col_a] - 1 do
        --                 if rows[mid_y]:sub(x, x) == "g" then found_g = true end
        --             end
        --             luassert.is_true(found_g,
        --                 "no 'g' in gap center row for bridge {" .. a .. "," .. b .. "}")
        --         else
        --             -- Horizontal edge: gap in x; carved y is the exit position.
        --             local gap_x_lo = x_start(col_a) + grid.col_widths[col_a]
        --             local gap_x_hi = x_start(col_a + 1) - 1
        --             local mid_x    = gap_x_lo + math.floor((gap_x_hi - gap_x_lo) / 2)
        --             local found_g  = false
        --             for y = y_start(row_a), y_start(row_a) + grid.row_heights[row_a] - 1 do
        --                 if rows[y]:sub(mid_x, mid_x) == "g" then found_g = true end
        --             end
        --             luassert.is_true(found_g,
        --                 "no 'g' in gap center col for bridge {" .. a .. "," .. b .. "}")
        --         end
        --     end
        -- end)

        it("same RNG state produces identical grids (AC#4 reproducibility)", function()
            local theme = make_theme()
            local grid  = make_grid()
            local gen_result, rng = generate(7)
            local state = rng:get_state()

            local rng_a = random.new(1)
            rng_a:set_state(state)
            local rows_a = glyph_grid.assemble(theme, grid, gen_result, {}, rng_a).rows

            local rng_b = random.new(1)
            rng_b:set_state(state)
            local rows_b = glyph_grid.assemble(theme, grid, gen_result, {}, rng_b).rows

            for y = 1, 16 do
                luassert.are_equal(rows_a[y], rows_b[y],
                    "row " .. y .. " differs between identical RNG runs")
            end
        end)

        it("all passable tiles are reachable from the deployment cell (AC#4 connectivity)", function()
            local theme = make_theme()
            local grid  = make_grid()
            local gen_result, rng = generate(11)
            local rows = glyph_grid.assemble(theme, grid, gen_result, {}, rng).rows

            -- Find deployment cell's top-left interior tile as flood-fill seed.
            local grid_w = #grid.col_widths
            local dep    = gen_result.deployment_cell
            local dep_col = ((dep - 1) % grid_w) + 1
            local dep_row = math.floor((dep - 1) / grid_w) + 1
            local sx = grid.border_left + 1
            for c = 1, dep_col - 1 do sx = sx + grid.col_widths[c] + grid.col_walls[c] end
            local sy = grid.border_top + 1
            for r = 1, dep_row - 1 do sy = sy + grid.row_heights[r] + grid.row_walls[r] end

            local reachable = flood_fill(rows, sx, sy)
            local total     = count_passable(rows)

            luassert.are_equal(total, reachable,
                "flood-fill reached " .. reachable .. " of " .. total .. " passable tiles")
        end)

        -- -----------------------------------------------------------------------
        -- Off-screen exit tests (bordered grid with 1-tile border margins)
        -- -----------------------------------------------------------------------

        it("returns offscreen_exits as empty table when offscreen_edges is empty", function()
            local gen_result, rng = generate(1)
            local assembled = glyph_grid.assemble(make_theme(), make_grid(), gen_result, {}, rng)
            luassert.is_table(assembled.offscreen_exits)
            luassert.are_equal(0, #assembled.offscreen_exits)
        end)

        it("carves a floor tile at the west border for a west off-screen edge on cell 1", function()
            -- Cell 1 is col=1, row=1.  Its west border is x=1 (border_left=1).
            -- The 6×6 chunk's west exit zone maps to y=[2..7] in map coords
            -- (cell_y_start=2, zone.min=2, zone.max=7 → map [2..7]).
            -- Expect at least one '.' at x=1 within y=[2..7].
            local offscreen_edges = { { cell_index = 1, face = "west" } }
            local gen_result, rng = generate_bordered(1, offscreen_edges)
            local assembled = glyph_grid.assemble(
                make_theme(), make_bordered_grid(), gen_result, offscreen_edges, rng)
            local rows = assembled.rows

            local found_floor = false
            for y = 2, 7 do
                if rows[y]:sub(1, 1) == "." then found_floor = true; break end
            end
            luassert.is_true(found_floor, "expected '.' at x=1 in y=[2..7] for west off-screen exit")
        end)

        it("records one offscreen_exits entry with correct face and in-range min/max", function()
            local offscreen_edges = { { cell_index = 1, face = "west" } }
            local gen_result, rng = generate_bordered(2, offscreen_edges)
            local assembled = glyph_grid.assemble(
                make_theme(), make_bordered_grid(), gen_result, offscreen_edges, rng)

            luassert.are_equal(1, #assembled.offscreen_exits)
            local exit = assembled.offscreen_exits[1]
            luassert.are_equal("west", exit.face)
            luassert.is_not_nil(exit.min)
            luassert.is_not_nil(exit.max)
            -- The exit zone y-coords for cell 1 west: [2..7]
            luassert.is_true(exit.min >= 2 and exit.max <= 7,
                "exit min=" .. tostring(exit.min) .. " max=" .. tostring(exit.max)
                .. " not in [2..7]")
        end)

        it("carves the north border for a north off-screen edge on cell 1", function()
            -- Cell 1 (col=1, row=1). North border is y=1 (border_top=1).
            -- North exit zone maps to x=[2..7] in map coords.
            local offscreen_edges = { { cell_index = 1, face = "north" } }
            local gen_result, rng = generate_bordered(3, offscreen_edges)
            local assembled = glyph_grid.assemble(
                make_theme(), make_bordered_grid(), gen_result, offscreen_edges, rng)
            local rows = assembled.rows

            local found_floor = false
            for x = 2, 7 do
                if rows[1]:sub(x, x) == "." then found_floor = true; break end
            end
            luassert.is_true(found_floor, "expected '.' at y=1 in x=[2..7] for north off-screen exit")
        end)
    end)

    describe("scatter_enemies", function()
        --- 16×16 rows of all-floor glyphs.
        local function floor_rows()
            local rows = {}
            for i = 1, 16 do rows[i] = string.rep(".", 16) end
            return rows
        end

        --- RNG stub that always returns 0 from rndf() (every roll succeeds when prob > 0).
        local function always_hit_rng()
            return { rndf = function() return 0 end }
        end

        --- RNG stub that always returns 1 from rndf() (every roll fails).
        local function always_miss_rng()
            return { rndf = function() return 1 end }
        end

        it("replaces '.' with 'i' in non-special cell interiors at prob=1.0", function()
            local rows = floor_rows()
            local gen_result = { placement = { deployment_cell = 1 } }
            glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 1.0, always_hit_rng())

            -- Cell 1 (special — deployment): interior must remain '.'.
            luassert.are_equal(".", rows[1]:sub(1, 1), "cell 1 interior x=1,y=1 should stay '.'")
            luassert.are_equal(".", rows[7]:sub(7, 7), "cell 1 interior x=7,y=7 should stay '.'")

            -- Cell 2 (non-special): interior must be 'i'.
            luassert.are_equal("i", rows[1]:sub(10, 10), "cell 2 interior x=10,y=1 should be 'i'")
            luassert.are_equal("i", rows[7]:sub(16, 16), "cell 2 interior x=16,y=7 should be 'i'")

            -- Cell 3 (non-special): interior must be 'i'.
            luassert.are_equal("i", rows[10]:sub(1, 1), "cell 3 interior x=1,y=10 should be 'i'")

            -- Cell 4 (non-special): interior must be 'i'.
            luassert.are_equal("i", rows[10]:sub(10, 10), "cell 4 interior x=10,y=10 should be 'i'")

            -- Wall gap tiles (not in any cell interior): must remain '.'.
            luassert.are_equal(".", rows[1]:sub(8, 8),  "wall gap x=8,y=1 should stay '.'")
            luassert.are_equal(".", rows[8]:sub(1, 1),  "wall gap x=1,y=8 should stay '.'")
        end)

        it("makes no changes at prob=0.0", function()
            local rows = floor_rows()
            local gen_result = { placement = { deployment_cell = 1 } }
            glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 0.0, always_hit_rng())

            for y = 1, 16 do
                luassert.are_equal(string.rep(".", 16), rows[y], "row " .. y .. " should be unchanged")
            end
        end)

        it("makes no changes when rng always misses", function()
            local rows = floor_rows()
            local gen_result = { placement = { deployment_cell = 1 } }
            glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 1.0, always_miss_rng())

            for y = 1, 16 do
                luassert.are_equal(string.rep(".", 16), rows[y], "row " .. y .. " should be unchanged")
            end
        end)

        it("does not replace non-'.' glyphs", function()
            local rows = floor_rows()
            -- Place a '#' and a 'd' inside cell 2's interior (x=10, x=11, y=2).
            local r2 = rows[2]
            rows[2] = r2:sub(1, 9) .. "#d" .. r2:sub(12)
            local gen_result = { placement = { deployment_cell = 1 } }
            glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 1.0, always_hit_rng())

            luassert.are_equal("#", rows[2]:sub(10, 10), "# at x=10,y=2 must stay '#'")
            luassert.are_equal("d", rows[2]:sub(11, 11), "d at x=11,y=2 must stay 'd'")
        end)

        it("skips boss_cell and escape_cell as special cells", function()
            local rows = floor_rows()
            local gen_result = {
                placement = {
                    deployment_cell = 1,
                    boss_cell       = 2,
                    escape_cell     = 3,
                }
            }
            glyph_grid.scatter_enemies(rows, gen_result, make_grid(), 1.0, always_hit_rng())

            -- Cells 1, 2, 3 are special: interior must remain '.'.
            luassert.are_equal(".", rows[1]:sub(10, 10), "boss cell 2 interior should stay '.'")
            luassert.are_equal(".", rows[10]:sub(1, 1),  "escape cell 3 interior should stay '.'")
            -- Cell 4 is non-special: must be 'i'.
            luassert.are_equal("i", rows[10]:sub(10, 10), "cell 4 interior should be 'i'")
        end)
    end)
end)
