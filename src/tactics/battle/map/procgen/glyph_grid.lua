---@brief
--- Glyph grid assembly: place cell interiors, carve connections, place guards.
--- Implements spec §8 steps 8–11.

local graph_mod = require("src.tactics.battle.map.procgen.graph")

local MAP_SIZE = 16

local glyph_grid = {}

-- ---------------------------------------------------------------------------
-- Position helpers (mirrors chunk_selector.lua)
-- ---------------------------------------------------------------------------

---@param grid ProcgenGrid
---@param col integer
---@return integer
local function cell_x_start(grid, col)
    local x = grid.border_left + 1
    for c = 1, col - 1 do
        x = x + grid.col_widths[c] + grid.col_walls[c]
    end
    return x
end

---@param grid ProcgenGrid
---@param row integer
---@return integer
local function cell_y_start(grid, row)
    local y = grid.border_top + 1
    for r = 1, row - 1 do
        y = y + grid.row_heights[r] + grid.row_walls[r]
    end
    return y
end

--- Convert an ExitZone from chunk border coordinates to map coordinates.
---@param zone ExitZone?
---@param cell_start integer Interior start on the relevant axis.
---@return ExitZone?
local function zone_to_map(zone, cell_start)
    if not zone then return nil end
    return { min = cell_start + zone.min - 2, max = cell_start + zone.max - 2 }
end

-- ---------------------------------------------------------------------------
-- RNG helpers
-- ---------------------------------------------------------------------------

--- Roll a connection width from `weights` clamped to [1, max_w].
---@param weights table<integer, integer>
---@param max_w integer
---@param rng RngInstance
---@return integer
local function roll_exit_width(weights, max_w, rng)
    local pool = {}
    for w = 1, max_w do
        local wt = weights[w] or 0
        for _ = 1, wt do
            table.insert(pool, w)
        end
    end
    if #pool == 0 then return 1 end
    return rng:choose_random_from_list(pool)
end

--- Roll a start position for an exit of width `w` within [ov_min, ov_max].
---@param ov_min integer
---@param ov_max integer
---@param w integer
---@param rng RngInstance
---@return integer
local function roll_exit_pos(ov_min, ov_max, w, rng)
    local max_start = ov_max - w + 1
    if max_start <= ov_min then return ov_min end
    return ov_min + rng:rndi(max_start - ov_min + 1)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Assemble a 16×16 glyph grid from the given chunk generation result.
--- Steps 8–11 of the spec: roll exit widths/positions, place cell interiors,
--- fill walls, carve connections, and mark width-1 bridge passages with 'g'.
---@param theme ProcgenTheme
---@param grid ProcgenGrid
---@param gen_result ChunkGenerationResult
---@param rng RngInstance
---@return string[]  16-element array of 16-character strings
function glyph_grid.assemble(theme, grid, gen_result, rng)
    local g          = gen_result.graph
    local assignment = gen_result.assignment
    local grid_w     = #grid.col_widths
    local grid_h     = #grid.row_heights
    local n          = grid_w * grid_h

    -- 1. Initialise 16×16 with wall glyphs.
    local cells = {}
    for y = 1, MAP_SIZE do
        cells[y] = {}
        for x = 1, MAP_SIZE do
            cells[y][x] = "#"
        end
    end

    -- 2. Place each cell's interior into the grid.
    for idx = 1, n do
        local col   = ((idx - 1) % grid_w) + 1
        local row   = math.floor((idx - 1) / grid_w) + 1
        local chunk = assignment[idx]
        local x0    = cell_x_start(grid, col)
        local y0    = cell_y_start(grid, row)
        -- chunk.rows includes border ring; interior occupies rows [2..h+1], cols [2..w+1].
        for cy = 2, chunk.height + 1 do
            local row_str = chunk.rows[cy]
            for cx = 2, chunk.width + 1 do
                cells[y0 + (cy - 2)][x0 + (cx - 2)] = row_str:sub(cx, cx)
            end
        end
    end

    -- 3. Pre-compute which edges are bridges.
    local bridge_key = {}
    for _, e in ipairs(graph_mod.bridges(g)) do
        bridge_key[e[1] .. "," .. e[2]] = true
    end

    -- 4. Roll exit widths/positions, carve connections, record guard centres.
    local guards = {}
    for _, e in ipairs(g.edges) do
        local a, b   = e[1], e[2]
        local col_a  = ((a - 1) % grid_w) + 1
        local row_a  = math.floor((a - 1) / grid_w) + 1

        local ov_min, ov_max
        local gap_lo, gap_hi
        local is_vert  -- true when A is directly north of B

        if b - a == grid_w then
            -- Vertical edge: A north of B.  Exit zones are x-coords; gap is in y.
            is_vert = true
            local x0 = cell_x_start(grid, col_a)
            local za  = zone_to_map(assignment[a].exits.south, x0)
            local zb  = zone_to_map(assignment[b].exits.north, x0)
            ---@cast za ExitZone
            ---@cast zb ExitZone
            ov_min  = math.max(za.min, zb.min)
            ov_max  = math.min(za.max, zb.max)
            gap_lo  = cell_y_start(grid, row_a) + grid.row_heights[row_a]
            gap_hi  = cell_y_start(grid, row_a + 1) - 1
        else
            -- Horizontal edge: A west of B.  Exit zones are y-coords; gap is in x.
            is_vert = false
            local y0 = cell_y_start(grid, row_a)
            local za  = zone_to_map(assignment[a].exits.east, y0)
            local zb  = zone_to_map(assignment[b].exits.west, y0)
            ---@cast za ExitZone
            ---@cast zb ExitZone
            ov_min  = math.max(za.min, zb.min)
            ov_max  = math.min(za.max, zb.max)
            gap_lo  = cell_x_start(grid, col_a) + grid.col_widths[col_a]
            gap_hi  = cell_x_start(grid, col_a + 1) - 1
        end

        local ov_w = ov_max - ov_min + 1
        local w    = roll_exit_width(theme.exit_width_weights, ov_w, rng)
        local pos  = roll_exit_pos(ov_min, ov_max, w, rng)

        -- Carve: erase wall tiles through the full gap depth.
        for gap = gap_lo, gap_hi do
            for tile = pos, pos + w - 1 do
                if is_vert then
                    cells[gap][tile] = "."
                else
                    cells[tile][gap] = "."
                end
            end
        end

        -- Record guard centre for width-1 bridges.
        if bridge_key[a .. "," .. b] and w == 1 then
            local mid_gap = gap_lo + math.floor((gap_hi - gap_lo) / 2)
            local cx, cy
            if is_vert then
                cx = pos
                cy = mid_gap
            else
                cx = mid_gap
                cy = pos
            end
            table.insert(guards, { cx = cx, cy = cy })
        end
    end

    -- 5. Place 'g' (enemy_guard) at each recorded guard centre.
    for _, guard in ipairs(guards) do
        cells[guard.cy][guard.cx] = "g"
    end

    -- 6. Convert to string rows.
    local rows = {}
    for y = 1, MAP_SIZE do
        rows[y] = table.concat(cells[y])
    end

    return rows
end

return glyph_grid
