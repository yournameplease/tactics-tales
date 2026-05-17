---@brief
--- Theme definitions for procedural map generation. See
--- docs/specs/procgen-map-spec.md §6.

---@class ProcgenTheme
---@field wall_thickness integer Tiles between adjacent cell interiors. Minimum 1.
---@field border_margin integer Tiles around the map edge. Minimum 0.
---@field grid_shapes integer[][] Valid {cols, rows} macro-grid shapes.
---@field distributions table<integer, integer[][]> Per-axis-length list of valid cell-size distributions.
---@field exit_width_weights table<integer, integer> Map of connection width -> weight.
---@field extra_edge_probability number Per-pair probability of adding an edge beyond the spanning tree.

local MAP_SIZE = 16

local themes = {}

--- Validate that a distribution fits the budget constraint for `n` cells.
---@param theme ProcgenTheme
---@param distribution integer[]
---@param n integer
---@return boolean ok
---@return string? err
local function check_distribution(theme, distribution, n)
    if #distribution ~= n then
        return false, "distribution length " .. #distribution .. " ≠ expected cell count " .. n
    end
    for i, w in ipairs(distribution) do
        if w < 3 then
            return false, "cell " .. i .. " width " .. w .. " < minimum 3"
        end
    end
    local sum = 0
    for _, w in ipairs(distribution) do sum = sum + w end
    local total = sum + (n - 1) * theme.wall_thickness + 2 * theme.border_margin
    if total ~= MAP_SIZE then
        return false, "budget " .. total .. " ≠ " .. MAP_SIZE .. " for distribution"
    end
    return true
end

--- Hard-error if any distribution in `theme` violates the budget constraint or
--- cell-dim minimum.
---@param theme ProcgenTheme
function themes.validate(theme)
    assert(theme.wall_thickness >= 1, "wall_thickness must be ≥ 1")
    assert(theme.border_margin >= 0, "border_margin must be ≥ 0")
    for n, dists in pairs(theme.distributions) do
        for i, dist in ipairs(dists) do
            local ok, err = check_distribution(theme, dist, n)
            if not ok then
                error("theme distribution #" .. i .. " for n=" .. n .. ": " .. err)
            end
        end
    end
    for _, shape in ipairs(theme.grid_shapes) do
        local w, h = shape[1], shape[2]
        assert(theme.distributions[w], "grid shape needs distributions[" .. w .. "]")
        assert(theme.distributions[h], "grid shape needs distributions[" .. h .. "]")
    end
end

---@class ProcgenGrid
---@field col_widths integer[]
---@field row_heights integer[]

--- Roll a macro-grid shape and per-axis cell-size distributions.
---@param theme ProcgenTheme
---@param rng RngInstance
---@return ProcgenGrid
function themes.roll_grid(theme, rng)
    local shape = rng:choose_random_from_list(theme.grid_shapes)
    local w, h = shape[1], shape[2]
    local col_widths = rng:choose_random_from_list(theme.distributions[w])
    local row_heights = rng:choose_random_from_list(theme.distributions[h])
    return { col_widths = col_widths, row_heights = row_heights }
end

themes.castle = {
    wall_thickness = 2,
    border_margin = 1,
    -- grid_shapes = { { 3, 3 }, { 2, 2 } },  -- 2x2 commented out until chunks authored
    grid_shapes = { { 3, 3 } },
    distributions = {
        [3] = { { 4, 3, 3 }, { 3, 4, 3 }, { 3, 3, 4 } },
        -- [2] = { { 6, 6 } },  -- 2x2 commented out until chunks authored
    },
    exit_width_weights = { [1] = 3, [2] = 1 },
    extra_edge_probability = 0.2,
}

themes.cave = {
    wall_thickness = 2,
    border_margin = 1,
    grid_shapes = { { 3, 3 }, { 2, 2 } },
    distributions = {
        [3] = { { 4, 3, 3 }, { 3, 4, 3 }, { 3, 3, 4 } },
        [2] = { { 6, 6 } },
    },
    exit_width_weights = { [1] = 1, [2] = 3, [3] = 3, [4] = 1 },
    extra_edge_probability = 0.35,
}

themes.validate(themes.castle)
themes.validate(themes.cave)

return themes
