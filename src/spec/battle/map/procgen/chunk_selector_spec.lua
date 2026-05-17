require("src.spec.picotron_shim")

local luassert = require("luassert")

local chunk_selector = require("src.tactics.battle.map.procgen.chunk_selector")
local graph = require("src.tactics.battle.map.procgen.graph")
local random = require("src.tactics.util.random")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Minimal theme for tests: no wall gap, no border margin.
---@return ProcgenTheme
local function make_theme()
    return {
        wall_thickness = 0,
        border_margin = 0,
        extra_edge_probability = 0,
        exit_width_weights = { [1] = 1 },
    }
end

--- 2×2-cell grid, each cell 3×3 interior.
---@return ProcgenGrid
local function make_2x2_grid()
    return { col_widths = { 3, 3 }, row_heights = { 3, 3 } }
end

--- 1×2-cell grid (single column, two rows), each cell 3×3 interior.
---@return ProcgenGrid
local function make_1x2_grid()
    return { col_widths = { 3 }, row_heights = { 3, 3 } }
end

--- 3×3 interior (5×5 full) chunk with exits on all four faces.
---@param name string
---@param is_deployment boolean?
---@return ChunkRecord
local function all_exits_chunk(name, is_deployment)
    local tags = is_deployment and { "deployment" } or {}
    local inner = is_deployment and "d" or "."
    return {
        name = name,
        width = 3, height = 3,
        tags = tags,
        rows = {
            "#^^^#",
            "<" .. inner .. "..>",
            "<...>",
            "<...>",
            "#vvv#",
        },
        exits = {
            north = { min = 2, max = 4 },
            south = { min = 2, max = 4 },
            east  = { min = 2, max = 4 },
            west  = { min = 2, max = 4 },
        },
    }
end

--- Chunk with south exit at position 2 only (leftmost).
--- For a 1×2 vertical grid, incompatible with `north_last_chunk`.
---@param name string
---@return ChunkRecord
local function south_first_chunk(name)
    return {
        name = name,
        width = 3, height = 3,
        tags = {},
        rows = { "#####", "#...#", "#...#", "#...#", "#v###" },
        exits = { north = nil, south = { min = 2, max = 2 }, east = nil, west = nil },
    }
end

--- Chunk with north exit at position 4 only (rightmost).
--- Incompatible with `south_first_chunk` — exit zones never overlap.
---@param name string
---@return ChunkRecord
local function north_last_chunk(name)
    return {
        name = name,
        width = 3, height = 3,
        tags = {},
        rows = { "###^#", "#...#", "#...#", "#...#", "#####" },
        exits = { north = { min = 4, max = 4 }, south = nil, east = nil, west = nil },
    }
end

--- Generate a spanning-tree graph for a 2×2 grid.
---@param seed integer?
---@return ConnectionGraph
local function make_2x2_graph(seed)
    return graph.generate(make_theme(), 2, 2, random.new(seed or 1))
end

--- Generate the only possible graph for a 1×2 grid (single edge {1,2}).
---@return ConnectionGraph
local function make_1x2_graph()
    return graph.generate(make_theme(), 1, 2, random.new(1))
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.battle.map.procgen.chunk_selector", function()
    describe("select", function()
        it("returns an assignment with a chunk for each cell", function()
            local pool = {
                all_exits_chunk("normal_1"),
                all_exits_chunk("normal_2"),
                all_exits_chunk("deploy_1", true),
            }
            local rng = random.new(42)
            local result = chunk_selector.select(make_theme(), make_2x2_grid(), make_2x2_graph(), pool, rng)

            luassert.is_not_nil(result)
            luassert.is_not_nil(result.assignment)
            luassert.are_equal(4, #result.assignment)
        end)

        it("assigns chunks whose dimensions match each cell", function()
            local pool = {
                all_exits_chunk("normal"),
                all_exits_chunk("deploy", true),
            }
            local rng = random.new(10)
            local result = chunk_selector.select(make_theme(), make_2x2_grid(), make_2x2_graph(), pool, rng)

            luassert.is_not_nil(result)
            for _, chunk in ipairs(result.assignment) do
                luassert.are_equal(3, chunk.width)
                luassert.are_equal(3, chunk.height)
            end
        end)

        it("places exactly one deployment-tagged chunk", function()
            local pool = {
                all_exits_chunk("normal_1"),
                all_exits_chunk("normal_2"),
                all_exits_chunk("deploy", true),
            }
            local rng = random.new(7)
            local result = chunk_selector.select(make_theme(), make_2x2_grid(), make_2x2_graph(), pool, rng)

            luassert.is_not_nil(result)
            local deploy_count = 0
            for _, chunk in ipairs(result.assignment) do
                for _, tag in ipairs(chunk.tags) do
                    if tag == "deployment" then deploy_count = deploy_count + 1 end
                end
            end
            luassert.are_equal(1, deploy_count)
        end)

        it("returns the deployment_cell index of the cell that holds the deployment chunk", function()
            local pool = {
                all_exits_chunk("normal"),
                all_exits_chunk("deploy", true),
            }
            local rng = random.new(3)
            local result = chunk_selector.select(make_theme(), make_2x2_grid(), make_2x2_graph(), pool, rng)

            luassert.is_not_nil(result)
            local dep_cell = result.deployment_cell
            local chunk = result.assignment[dep_cell]
            local has_tag = false
            for _, t in ipairs(chunk.tags) do
                if t == "deployment" then has_tag = true end
            end
            luassert.is_true(has_tag)
        end)

        it("all graph edges have at least one overlapping exit-zone tile in map coordinates", function()
            local pool = {
                all_exits_chunk("normal"),
                all_exits_chunk("deploy", true),
            }
            local rng = random.new(99)
            local g = make_2x2_graph(99)
            local theme = make_theme()
            local grid = make_2x2_grid()
            local result = chunk_selector.select(theme, grid, g, pool, rng)

            luassert.is_not_nil(result)
            -- For each edge, verify exit zones overlap in map coordinates.
            for _, e in ipairs(g.edges) do
                local a, b = e[1], e[2]
                local ca = result.assignment[a]
                local cb = result.assignment[b]
                local w = #grid.col_widths
                if b - a == w then
                    -- Vertical edge: check south/north exits in x-coords.
                    local col = ((a - 1) % w) + 1
                    local x_start = theme.border_margin + 1
                    for c = 1, col - 1 do x_start = x_start + grid.col_widths[c] + theme.wall_thickness end
                    local sa = ca.exits.south
                    local nb = cb.exits.north
                    luassert.is_not_nil(sa)
                    luassert.is_not_nil(nb)
                    local lo = math.max(x_start + sa.min - 2, x_start + nb.min - 2)
                    local hi = math.min(x_start + sa.max - 2, x_start + nb.max - 2)
                    luassert.is_true(hi - lo + 1 >= 1)
                else
                    -- Horizontal edge: check east/west exits in y-coords.
                    local row = math.floor((a - 1) / w) + 1
                    local y_start = theme.border_margin + 1
                    for r = 1, row - 1 do y_start = y_start + grid.row_heights[r] + theme.wall_thickness end
                    local ea = ca.exits.east
                    local wb = cb.exits.west
                    luassert.is_not_nil(ea)
                    luassert.is_not_nil(wb)
                    local lo = math.max(y_start + ea.min - 2, y_start + wb.min - 2)
                    local hi = math.min(y_start + ea.max - 2, y_start + wb.max - 2)
                    luassert.is_true(hi - lo + 1 >= 1)
                end
            end
        end)

        it("returns nil and an error string when the pool cannot satisfy exit overlaps after retries", function()
            -- south_first_chunk and north_last_chunk never overlap on a 1×2 vertical grid.
            local pool = {
                south_first_chunk("top"),
                north_last_chunk("bot"),
            }
            local rng = random.new(1)
            local result, err = chunk_selector.select(make_theme(), make_1x2_grid(), make_1x2_graph(), pool, rng)

            luassert.is_nil(result)
            luassert.is_not_nil(err)
            luassert.is_true(type(err) == "string" and #err > 0)
        end)

        it("exercises the retry path: succeeds despite some incompatible chunk pairs in the pool", function()
            -- Pool has two chunks per cell. One pair is incompatible, one is compatible.
            -- The retry loop should eventually find the compatible combination.
            local pool = {
                -- full-exit chunks (compatible with each other)
                all_exits_chunk("good_a"),
                all_exits_chunk("good_b"),
                all_exits_chunk("deploy_good", true),
                -- south-only-first: compatible with itself but potentially bad combos exist
                south_first_chunk("top_bad"),
                north_last_chunk("bot_bad"),
            }
            -- Only the all_exits chunks satisfy the 1×2 grid's exit overlap requirement.
            -- The retry loop should find them.
            local rng = random.new(5)
            local result = chunk_selector.select(make_theme(), make_1x2_grid(), make_1x2_graph(), pool, rng)

            luassert.is_not_nil(result)
        end)
    end)

    describe("generate", function()
        it("returns assignment, deployment_cell, and graph on success", function()
            local pool = {
                all_exits_chunk("normal"),
                all_exits_chunk("deploy", true),
            }
            local rng = random.new(42)
            local result = chunk_selector.generate(make_theme(), make_2x2_grid(), pool, rng)

            luassert.is_not_nil(result)
            luassert.is_not_nil(result.assignment)
            luassert.is_not_nil(result.deployment_cell)
            luassert.is_not_nil(result.graph)
            luassert.are_equal(4, #result.assignment)
        end)

        it("errors when no compatible chunk assignment can be found after all graph retries", function()
            -- south_first and north_last never overlap; every graph regeneration also fails.
            local pool = {
                south_first_chunk("top"),
                north_last_chunk("bot"),
            }
            local rng = random.new(1)
            luassert.has_error(function()
                chunk_selector.generate(make_theme(), make_1x2_grid(), pool, rng)
            end)
        end)
    end)
end)
