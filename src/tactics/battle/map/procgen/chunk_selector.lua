---@brief
--- Chunk selection with deployment cell choice and exit-overlap retry.
--- See docs/specs/procgen-map-spec.md §8 steps 5–7.

local graph_mod     = require("src.tactics.battle.map.procgen.graph")
local grid_layout   = require("src.tactics.battle.map.procgen.grid_layout")
local placement_mod = require("src.tactics.battle.map.procgen.placement")

local MAX_CELL_RETRIES = 10
local MAX_GRAPH_RETRIES = 10

local chunk_selector = {}

---@class ChunkSelection
---@field assignment ChunkRecord[]  1-indexed by cell index
---@field deployment_cell integer   1-based index of the deployment cell

---@class ChunkGenerationResult : ChunkSelection
---@field graph ConnectionGraph
---@field placement ProcgenPlacement
---@field offscreen_edges {cell_index: integer, face: string}[]

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

local SPECIAL_TAGS = { deployment = true, boss_room = true, escape_zone = true }

---@param chunk ChunkRecord
---@return string? first special tag found, or nil
local function get_special_tag(chunk)
    for _, t in ipairs(chunk.tags) do
        if SPECIAL_TAGS[t] then return t end
    end
    return nil
end

---@param chunk ChunkRecord
---@return boolean
local function chunk_has_enemies(chunk)
    for _, t in ipairs(chunk.tags) do
        if t == "has_enemies" then return true end
    end
    return false
end

---@param idx integer
---@param p ProcgenPlacement
---@return string?
local function cell_required_tag(idx, p)
    if idx == p.deployment_cell then return "deployment" end
    if idx == p.boss_cell        then return "boss_room"  end
    if idx == p.escape_cell      then return "escape_zone" end
    return nil
end

---@param idx integer
---@param placement ProcgenPlacement
---@return boolean?
local function cell_has_enemies_flag(idx, placement)
    if cell_required_tag(idx, placement) ~= nil then return nil end
    if placement.enemy_cells == nil then return false end
    return placement.enemy_cells[idx] == true
end

--- Filter `chunks` to those valid for a cell with interior dims `cw`×`ch`.
--- `required_tag` is the special tag required for this cell (nil for regular cells).
--- Only chunks with exit zones on all `faces` are included.
--- `has_enemies` applies only to regular cells: nil=no constraint, true=must have has_enemies tag,
--- false=must not have has_enemies tag.
---@param chunks ChunkRecord[]
---@param cw integer
---@param ch integer
---@param required_tag string?
---@param faces table<string, true>
---@param has_enemies boolean?
---@return ChunkRecord[]
local function filter_candidates(chunks, cw, ch, required_tag, faces, has_enemies)
    local result = {}
    for _, chunk in ipairs(chunks) do
        if chunk.width == cw and chunk.height == ch then
            if get_special_tag(chunk) == required_tag then
                local ok = true
                for face in pairs(faces) do
                    if not chunk.exits[face] then ok = false; break end
                end
                -- Apply has_enemies constraint for regular cells only (required_tag == nil).
                if ok and has_enemies ~= nil then
                    if chunk_has_enemies(chunk) ~= has_enemies then ok = false end
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
--- Rooms are shown as hollow squares [ ]; special cells (deployment, boss_room,
--- escape_zone) are labelled A, B, C... with a legend below the grid.
--- Off-screen exits are shown as ^/v/</>/< arrows adjacent to the room.
---@param grid ProcgenGrid
---@param g ConnectionGraph
---@param offscreen_edges {cell_index: integer, face: string}[]?
---@param placement ProcgenPlacement?
---@return string
local function ascii_grid(grid, g, offscreen_edges, placement)
    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights

    local edge_set = {}
    for _, e in ipairs(g.edges) do
        edge_set[e[1] .. "," .. e[2]] = true
    end
    local function has_edge(a, b)
        local lo, hi = math.min(a, b), math.max(a, b)
        return edge_set[lo .. "," .. hi] == true
    end

    -- off[idx][face] = true
    local off = {}
    for _, oe in ipairs(offscreen_edges or {}) do
        off[oe.cell_index] = off[oe.cell_index] or {}
        off[oe.cell_index][oe.face] = true
    end

    -- Assign A/B/C labels to special cells and build legend lines.
    local cell_label = {}
    local legend = {}
    local next_lbl = string.byte("A")
    local function assign(idx, tag)
        if not idx or cell_label[idx] then return end
        local lbl = string.char(next_lbl)
        next_lbl = next_lbl + 1
        cell_label[idx] = lbl
        local n = 0
        for _ in pairs(off[idx] or {}) do n = n + 1 end
        table.insert(legend, lbl .. ": " .. tag .. ", " .. n .. (n == 1 and " exit" or " exits"))
    end
    if placement then
        assign(placement.deployment_cell, "deployment")
        assign(placement.boss_cell,       "boss_room")
        assign(placement.escape_cell,     "escape_zone")
    end

    -- Each room occupies 3 chars "[ ]"; horizontal connectors are "---"/"   ".
    -- Vertical connector row uses " | "/" v "/" ^ "/"   " centered under each room.
    local function room_str(idx)
        return "[" .. (cell_label[idx] or " ") .. "]"
    end

    local function any_north_off(row)
        for col = 1, grid_w do
            local idx = (row - 1) * grid_w + col
            if off[idx] and off[idx].north then return true end
        end
        return false
    end

    local function any_south_off(row)
        for col = 1, grid_w do
            local idx = (row - 1) * grid_w + col
            if off[idx] and off[idx].south then return true end
        end
        return false
    end

    local lines = {}
    for row = 1, grid_h do
        -- North off-screen row (only when needed).
        if any_north_off(row) then
            local parts = {}
            for col = 1, grid_w do
                local idx = (row - 1) * grid_w + col
                table.insert(parts, (off[idx] and off[idx].north) and " ^ " or "   ")
                if col < grid_w then table.insert(parts, "   ") end
            end
            table.insert(lines, table.concat(parts))
        end

        -- Room row.
        local parts = {}
        for col = 1, grid_w do
            local idx = (row - 1) * grid_w + col
            -- West off-screen arrow (first column only to avoid connector conflict).
            if col == 1 and off[idx] and off[idx].west then
                table.insert(parts, "<")
            end
            table.insert(parts, room_str(idx))
            if col < grid_w then
                local right = idx + 1
                table.insert(parts, has_edge(idx, right) and "---" or "   ")
            else
                -- East off-screen arrow on the last column.
                if off[idx] and off[idx].east then
                    table.insert(parts, ">")
                end
            end
        end
        table.insert(lines, table.concat(parts))

        -- South connector / off-screen row.
        if row < grid_h or any_south_off(row) then
            local vparts = {}
            for col = 1, grid_w do
                local idx = (row - 1) * grid_w + col
                local below = idx + grid_w
                local s_off  = off[idx] and off[idx].south
                local s_edge = row < grid_h and has_edge(idx, below)
                if s_off then
                    table.insert(vparts, " v ")
                elseif s_edge then
                    table.insert(vparts, " | ")
                else
                    table.insert(vparts, "   ")
                end
                if col < grid_w then table.insert(vparts, "   ") end
            end
            table.insert(lines, table.concat(vparts))
        end
    end

    local result = table.concat(lines, "\n")
    if #legend > 0 then
        result = result .. "\n" .. table.concat(legend, "\n")
    end
    return result
end

--- Log diagnostic information for a failed generation attempt.
---@param grid ProcgenGrid
---@param g ConnectionGraph
---@param attempt integer
---@param offscreen_edges {cell_index: integer, face: string}[]?
---@param placement ProcgenPlacement?
local function log_failure(grid, g, attempt, offscreen_edges, placement)
    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights
    local col_str = "{" .. table.concat(grid.col_widths, ", ") .. "}"
    local row_str = "{" .. table.concat(grid.row_heights, ", ") .. "}"
    log.warn(
        "chunk_selector attempt " .. attempt .. " failed"
        .. "  grid=" .. grid_w .. "x" .. grid_h
        .. "  col_widths=" .. col_str
        .. "  row_heights=" .. row_str
        .. "\n" .. ascii_grid(grid, g, offscreen_edges, placement)
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
---@param placement ProcgenPlacement
---@return ChunkSelection?
---@return string?
function chunk_selector.select(grid, g, chunks, rng, offscreen_edges, placement)
    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights
    local n = grid_w * grid_h

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
        local required_tag = cell_required_tag(idx, placement)
        local has_enemies_flag = cell_has_enemies_flag(idx, placement)
        local candidates = filter_candidates(
            chunks,
            grid.col_widths[col],
            grid.row_heights[row],
            required_tag,
            all_faces(idx),
            has_enemies_flag
        )
        if #candidates == 0 then
            return nil, "no valid chunk for cell " .. idx
                .. " (required_tag=" .. tostring(required_tag) .. ")"
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
                local rt = cell_required_tag(idx, placement)
                local hef = cell_has_enemies_flag(idx, placement)
                local candidates = filter_candidates(
                    chunks,
                    grid.col_widths[col],
                    grid.row_heights[row],
                    rt,
                    all_faces(idx),
                    hef
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

    return { assignment = assignment, deployment_cell = placement.deployment_cell }
end

--- Generate chunks for all cells, regenerating the connection graph up to MAX_GRAPH_RETRIES
--- times if exit overlap cannot be satisfied.
--- Off-screen edges are rolled internally after placement so per-cell exit counts can be
--- enforced: boss_cell=0, escape_cell=1, deployment_cell=1.
---@param theme ProcgenTheme
---@param grid ProcgenGrid
---@param chunks ChunkRecord[]
---@param rng RngInstance
---@param objective string?  Battle objective type passed to placement_mod.select
---@param enemy_distribution string?  "room_based" or "scatter"; nil defaults to "room_based"
---@return ChunkGenerationResult
function chunk_selector.generate(theme, grid, chunks, rng, objective, enemy_distribution)
    objective = objective or "rout"
    local grid_w = #grid.col_widths
    local grid_h = #grid.row_heights
    for attempt = 1, MAX_GRAPH_RETRIES do
        local g = graph_mod.generate(theme, grid_w, grid_h, rng)
        local p = placement_mod.select(g, objective, rng, theme, enemy_distribution)
        local cell_requirements = { [p.deployment_cell] = 1 }
        if p.boss_cell   then cell_requirements[p.boss_cell]   = 0 end
        if p.escape_cell then cell_requirements[p.escape_cell] = 1 end
        local offscreen_edges = graph_mod.roll_offscreen_edges(theme, grid_w, grid_h, rng, cell_requirements)
        local result = chunk_selector.select(grid, g, chunks, rng, offscreen_edges, p)
        if result then
            return {
                assignment      = result.assignment,
                deployment_cell = p.deployment_cell,
                placement       = p,
                graph           = g,
                offscreen_edges = offscreen_edges,
            }
        end
        log_failure(grid, g, attempt, offscreen_edges, p)
    end
    error("chunk_selector: cannot satisfy connection graph after "
        .. MAX_GRAPH_RETRIES .. " regeneration attempts")
end

return chunk_selector
