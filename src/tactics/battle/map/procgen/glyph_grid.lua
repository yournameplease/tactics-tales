---@brief
--- Glyph grid assembly: place cell interiors, carve connections, place guards.
--- Implements spec §8 steps 8–11.

local graph_mod   = require("src.tactics.battle.map.procgen.graph")
local grid_layout = require("src.tactics.battle.map.procgen.grid_layout")

local MAP_SIZE = 16

local glyph_grid = {}

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

--- Carve a passage through `cells` and return its position and width.
--- Rolls width from `weights` and a start position within the overlap zone,
--- then erases wall tiles across [gap_lo, gap_hi] on the perpendicular axis.
---@param cells string[][]
---@param is_vert boolean True when the passage runs north-south (gap moves in y).
---@param gap_lo integer First wall tile index on the gap axis.
---@param gap_hi integer Last wall tile index on the gap axis.
---@param ov_min integer Overlap zone start on the passage axis.
---@param ov_max integer Overlap zone end on the passage axis.
---@param weights table<integer, integer>
---@param rng RngInstance
---@return integer pos, integer w
local function carve_passage(cells, is_vert, gap_lo, gap_hi, ov_min, ov_max, weights, rng)
    local w   = roll_exit_width(weights, ov_max - ov_min + 1, rng)
    local pos = roll_exit_pos(ov_min, ov_max, w, rng)
    for gap = gap_lo, gap_hi do
        for tile = pos, pos + w - 1 do
            if is_vert then cells[gap][tile] = "."
            else            cells[tile][gap] = "." end
        end
    end
    return pos, w
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

---@class GlyphGridResult
---@field rows string[]  16-element array of 16-character glyph strings
---@field offscreen_exits {face: string, min: integer, max: integer}[]

--- Assemble a 16×16 glyph grid from the given chunk generation result.
--- Steps 8–11 of the spec: roll exit widths/positions, place cell interiors,
--- fill walls, carve connections, and mark width-1 bridge passages with 'g'.
--- Also carves off-screen border passages for each entry in `offscreen_edges`.
---@param theme ProcgenTheme
---@param grid ProcgenGrid
---@param gen_result ChunkGenerationResult
---@param offscreen_edges {cell_index: integer, face: string}[]
---@param rng RngInstance
---@return GlyphGridResult
function glyph_grid.assemble(theme, grid, gen_result, offscreen_edges, rng)
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
        local x0    = grid_layout.cell_x_start(grid, col)
        local y0    = grid_layout.cell_y_start(grid, row)
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
            local x0 = grid_layout.cell_x_start(grid, col_a)
            local za  = grid_layout.zone_to_map(assignment[a].exits.south, x0)
            local zb  = grid_layout.zone_to_map(assignment[b].exits.north, x0)
            ---@cast za ExitZone
            ---@cast zb ExitZone
            ov_min  = math.max(za.min, zb.min)
            ov_max  = math.min(za.max, zb.max)
            gap_lo  = grid_layout.cell_y_start(grid, row_a) + grid.row_heights[row_a]
            gap_hi  = grid_layout.cell_y_start(grid, row_a + 1) - 1
        else
            -- Horizontal edge: A west of B.  Exit zones are y-coords; gap is in x.
            is_vert = false
            local y0 = grid_layout.cell_y_start(grid, row_a)
            local za  = grid_layout.zone_to_map(assignment[a].exits.east, y0)
            local zb  = grid_layout.zone_to_map(assignment[b].exits.west, y0)
            ---@cast za ExitZone
            ---@cast zb ExitZone
            ov_min  = math.max(za.min, zb.min)
            ov_max  = math.min(za.max, zb.max)
            gap_lo  = grid_layout.cell_x_start(grid, col_a) + grid.col_widths[col_a]
            gap_hi  = grid_layout.cell_x_start(grid, col_a + 1) - 1
        end

        local pos, w = carve_passage(cells, is_vert, gap_lo, gap_hi, ov_min, ov_max,
            theme.exit_width_weights, rng)

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
    -- Disabled for balancing.  Consider adding with a percentage chance, or a total limit?
    -- for _, guard in ipairs(guards) do
    --     cells[guard.cy][guard.cx] = "t"
    -- end

    -- 6. Carve off-screen border passages and collect exit metadata.
    local offscreen_exits = {}
    local offscreen_grid_w = #grid.col_widths
    for _, oe in ipairs(offscreen_edges or {}) do
        local idx  = oe.cell_index
        local face = oe.face
        local col  = ((idx - 1) % offscreen_grid_w) + 1
        local row  = math.floor((idx - 1) / offscreen_grid_w) + 1
        local chunk = assignment[idx]

        -- Determine gap extents and exit-zone axis based on face direction.
        local gap_lo, gap_hi, ov_min, ov_max, is_vert
        if face == "west" then
            gap_lo  = 1
            gap_hi  = grid.border_left
            local y0 = grid_layout.cell_y_start(grid, row)
            local z  = grid_layout.zone_to_map(chunk.exits.west, y0)
            if not z or gap_hi < gap_lo then goto continue end
            ov_min  = z.min
            ov_max  = z.max
            is_vert = false
        elseif face == "east" then
            gap_lo  = grid_layout.cell_x_start(grid, col) + grid.col_widths[col]
            gap_hi  = MAP_SIZE
            local y0 = grid_layout.cell_y_start(grid, row)
            local z  = grid_layout.zone_to_map(chunk.exits.east, y0)
            if not z or gap_hi < gap_lo then goto continue end
            ov_min  = z.min
            ov_max  = z.max
            is_vert = false
        elseif face == "north" then
            gap_lo  = 1
            gap_hi  = grid.border_top
            local x0 = grid_layout.cell_x_start(grid, col)
            local z  = grid_layout.zone_to_map(chunk.exits.north, x0)
            if not z or gap_hi < gap_lo then goto continue end
            ov_min  = z.min
            ov_max  = z.max
            is_vert = true
        elseif face == "south" then
            gap_lo  = grid_layout.cell_y_start(grid, row) + grid.row_heights[row]
            gap_hi  = MAP_SIZE
            local x0 = grid_layout.cell_x_start(grid, col)
            local z  = grid_layout.zone_to_map(chunk.exits.south, x0)
            if not z or gap_hi < gap_lo then goto continue end
            ov_min  = z.min
            ov_max  = z.max
            is_vert = true
        else
            goto continue
        end

        local pos, w = carve_passage(cells, is_vert, gap_lo, gap_hi, ov_min, ov_max,
            theme.exit_width_weights, rng)
        offscreen_exits[#offscreen_exits + 1] = { face = face, min = pos, max = pos + w - 1 }

        ::continue::
    end

    -- 7. Convert to string rows.
    local rows = {}
    for y = 1, MAP_SIZE do
        rows[y] = table.concat(cells[y])
    end

    return { rows = rows, offscreen_exits = offscreen_exits }
end

return glyph_grid
