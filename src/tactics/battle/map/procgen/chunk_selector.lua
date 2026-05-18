---@brief
--- Chunk selection with deployment cell choice and exit-overlap retry.
--- See docs/specs/procgen-map-spec.md §8 steps 5–7.

local graph_mod    = require("src.tactics.battle.map.procgen.graph")
local grid_layout  = require("src.tactics.battle.map.procgen.grid_layout")

local MAX_CELL_RETRIES = 10
local MAX_GRAPH_RETRIES = 10

local chunk_selector = {}

---@class ChunkSelection
---@field assignment ChunkRecord[]  1-indexed by cell index
---@field deployment_cell integer   1-based index of the deployment cell

---@class ChunkGenerationResult : ChunkSelection
---@field graph ConnectionGraph

-- ---------------------------------------------------------------------------
-- Exit-zone helpers
-- ---------------------------------------------------------------------------

--- Compute the overlap width of two map-coordinate ExitZones.
---@param z1 ExitZone?
---@param z2 ExitZone?
---@return integer
local function overlap_width(z1, z2)
    if not z1 or not z2 then return 0 end
    local lo = math.max(z1.min, z2.min)
    local hi = math.min(z1.max, z2.max)
    return math.max(0, hi - lo + 1)
end

-- ---------------------------------------------------------------------------
-- Candidate filtering
-- ---------------------------------------------------------------------------

--- Required exit faces for cell `idx` given its neighbour list and grid width.
---@param idx integer
---@param adj integer[]
---@param grid_w integer
---@return table<string, true>
local function required_faces(idx, adj, grid_w)
    local faces = {}
    for _, nb in ipairs(adj) do
        local d = nb - idx
        -- Check vertical (±grid_w) before horizontal (±1) to handle w=1 grids correctly.
        if d == grid_w then faces.south = true
        elseif d == -grid_w then faces.north = true
        elseif d == 1 then faces.east = true
        elseif d == -1 then faces.west = true
        end
    end
    return faces
end

---@param chunk ChunkRecord
---@return boolean
local function has_deployment_tag(chunk)
    for _, t in ipairs(chunk.tags) do
        if t == "deployment" then return true end
    end
    return false
end

--- Filter `chunks` to those valid for a cell with interior dims `cw`×`ch`.
--- `need_deployment` gates whether the deployment tag is required or excluded.
--- Only chunks with exit zones on all `faces` are included.
---@param chunks ChunkRecord[]
---@param cw integer
---@param ch integer
---@param need_deployment boolean
---@param faces table<string, true>
---@return ChunkRecord[]
local function filter_candidates(chunks, cw, ch, need_deployment, faces)
    local result = {}
    for _, chunk in ipairs(chunks) do
        if chunk.width == cw and chunk.height == ch then
            local is_dep = has_deployment_tag(chunk)
            if is_dep == need_deployment then
                local ok = true
                for face in pairs(faces) do
                    if not chunk.exits[face] then ok = false; break end
                end
                if ok then table.insert(result, chunk) end
            end
        end
    end
    return result
end

-- ---------------------------------------------------------------------------
-- Overlap validation
-- ---------------------------------------------------------------------------

--- Return the set of cell indices that participate in at least one failing edge.
---@param g ConnectionGraph
---@param assignment ChunkRecord[]
---@param grid ProcgenGrid
---@param grid_w integer
---@return integer[]
local function find_bad_cells(g, assignment, grid, grid_w)
    local bad, marked = {}, {}
    for _, e in ipairs(g.edges) do
        local a, b = e[1], e[2]
        local ov
        if b - a == grid_w then
            -- Vertical edge (north-south): check south/north exits in x-coords.
            local col = ((a - 1) % grid_w) + 1
            local x = grid_layout.cell_x_start(grid, col)
            ov = overlap_width(
                grid_layout.zone_to_map(assignment[a].exits.south, x),
                grid_layout.zone_to_map(assignment[b].exits.north, x)
            )
        else
            -- Horizontal edge (east-west): check east/west exits in y-coords.
            local row = math.floor((a - 1) / grid_w) + 1
            local y = grid_layout.cell_y_start(grid, row)
            ov = overlap_width(
                grid_layout.zone_to_map(assignment[a].exits.east, y),
                grid_layout.zone_to_map(assignment[b].exits.west, y)
            )
        end
        if ov < 1 then
            if not marked[a] then marked[a] = true; table.insert(bad, a) end
            if not marked[b] then marked[b] = true; table.insert(bad, b) end
        end
    end
    return bad
end

-- ---------------------------------------------------------------------------
-- Failure diagnostics
-- ---------------------------------------------------------------------------

--- Build a multi-line ASCII diagram of the meta-grid and return it as a string.
---@param grid ProcgenGrid
---@param g ConnectionGraph
---@return string
local function ascii_grid(grid, g)
    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights

    -- Build a set of edges for O(1) lookup.
    local edge_set = {}
    for _, e in ipairs(g.edges) do
        edge_set[e[1] .. "," .. e[2]] = true
    end
    local function has_edge(a, b)
        local lo, hi = math.min(a, b), math.max(a, b)
        return edge_set[lo .. "," .. hi] == true
    end

    local lines = {}
    for row = 1, grid_h do
        -- Room row.
        local parts = {}
        for col = 1, grid_w do
            local idx = (row - 1) * grid_w + col
            table.insert(parts, "O")
            if col < grid_w then
                local right = idx + 1
                table.insert(parts, has_edge(idx, right) and "-" or " ")
            end
        end
        table.insert(lines, table.concat(parts))

        -- Vertical connector row (omit after the last room row).
        if row < grid_h then
            local vparts = {}
            for col = 1, grid_w do
                local idx = (row - 1) * grid_w + col
                local below = idx + grid_w
                table.insert(vparts, has_edge(idx, below) and "|" or " ")
                if col < grid_w then table.insert(vparts, " ") end
            end
            table.insert(lines, table.concat(vparts))
        end
    end
    return table.concat(lines, "\n")
end

--- Log diagnostic information for a failed generation attempt.
---@param grid ProcgenGrid
---@param g ConnectionGraph
---@param attempt integer
local function log_failure(grid, g, attempt)
    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights
    local col_str = "{" .. table.concat(grid.col_widths, ", ") .. "}"
    local row_str = "{" .. table.concat(grid.row_heights, ", ") .. "}"
    log.warn(
        "chunk_selector attempt " .. attempt .. " failed"
        .. "  grid=" .. grid_w .. "x" .. grid_h
        .. "  col_widths=" .. col_str
        .. "  row_heights=" .. row_str
        .. "\n" .. ascii_grid(grid, g)
    )
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

--- Attempt to select a chunk for every cell in `grid` given a fixed connection graph `g`.
--- Retries cells with failing exit overlaps up to MAX_CELL_RETRIES times.
---@param grid ProcgenGrid
---@param g ConnectionGraph
---@param chunks ChunkRecord[]
---@param rng RngInstance
---@param offscreen_edges {cell_index: integer, face: string}[]?
---@return ChunkSelection?
---@return string?
function chunk_selector.select(grid, g, chunks, rng, offscreen_edges)
    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights
    local n = grid_w * grid_h

    local deployment_cell = rng:rndi(n) + 1

    -- Pre-compute additional faces required by off-screen edges.
    local offscreen_required = {}
    for _, oe in ipairs(offscreen_edges or {}) do
        if not offscreen_required[oe.cell_index] then
            offscreen_required[oe.cell_index] = {}
        end
        offscreen_required[oe.cell_index][oe.face] = true
    end

    local function all_faces(idx)
        local faces = required_faces(idx, g.adjacency[idx] or {}, grid_w)
        for face in pairs(offscreen_required[idx] or {}) do
            faces[face] = true
        end
        return faces
    end

    -- Initial chunk selection.
    local assignment = {}
    for idx = 1, n do
        local col = ((idx - 1) % grid_w) + 1
        local row = math.floor((idx - 1) / grid_w) + 1
        local candidates = filter_candidates(
            chunks,
            grid.col_widths[col],
            grid.row_heights[row],
            idx == deployment_cell,
            all_faces(idx)
        )
        if #candidates == 0 then
            return nil, "no valid chunk for cell " .. idx
                .. " (deployment=" .. tostring(idx == deployment_cell) .. ")"
        end
        assignment[idx] = rng:choose_random_from_list(candidates)
    end

    -- Retry loop: reselect cells with failing exit overlaps.
    local bad = find_bad_cells(g, assignment, grid, grid_w)
    if #bad > 0 then
        for _ = 1, MAX_CELL_RETRIES do
            for _, idx in ipairs(bad) do
                local col = ((idx - 1) % grid_w) + 1
                local row = math.floor((idx - 1) / grid_w) + 1
                local candidates = filter_candidates(
                    chunks,
                    grid.col_widths[col],
                    grid.row_heights[row],
                    idx == deployment_cell,
                    all_faces(idx)
                )
                if #candidates > 0 then
                    assignment[idx] = rng:choose_random_from_list(candidates)
                end
            end
            bad = find_bad_cells(g, assignment, grid, grid_w)
            if #bad == 0 then break end
        end
    end

    if #bad > 0 then
        return nil, "exit overlap retry budget exceeded: "
            .. #bad .. " cell(s) still failing after " .. MAX_CELL_RETRIES .. " retries"
    end

    return { assignment = assignment, deployment_cell = deployment_cell }
end

--- Generate chunks for all cells, regenerating the connection graph up to MAX_GRAPH_RETRIES
--- times if exit overlap cannot be satisfied.
---@param theme ProcgenTheme
---@param grid ProcgenGrid
---@param chunks ChunkRecord[]
---@param rng RngInstance
---@param offscreen_edges {cell_index: integer, face: string}[]?
---@return ChunkGenerationResult
function chunk_selector.generate(theme, grid, chunks, rng, offscreen_edges)
    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights
    for attempt = 1, MAX_GRAPH_RETRIES do
        local g = graph_mod.generate(theme, grid_w, grid_h, rng)
        local result = chunk_selector.select(grid, g, chunks, rng, offscreen_edges)
        if result then
            return {
                assignment = result.assignment,
                deployment_cell = result.deployment_cell,
                graph = g,
            }
        end
        log_failure(grid, g, attempt)
    end
    error("chunk_selector: cannot satisfy connection graph after "
        .. MAX_GRAPH_RETRIES .. " regeneration attempts")
end

return chunk_selector
