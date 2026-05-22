---@brief
--- Theme definitions for procedural map generation. See
--- docs/specs/procgen-map-spec.md §6.

---@class ProcgenTheme
---@field wall_thickness integer Minimum tiles between adjacent cell interiors. Minimum 1.
---@field wall_grow_probability number Per-wall-gap probability of adding 1 extra tile. Range [0, 1].
---@field grid_shapes integer[][] Valid {cols, rows} macro-grid shapes.
---@field distributions table<integer, integer[][]> Per-axis-length list of valid cell-size distributions.
---@field exit_width_weights table<integer, integer> Map of connection width -> weight.
---@field extra_edge_probability number Per-pair probability of adding an edge beyond the spanning tree.
---@field off_screen_edge_probability number Per-border-face probability of adding an off-screen exit. Range [0, 1].
---@field target_deployment_distance integer? BFS distance from objective cell to target for player spawn; falls back to max if unreachable.
---@field enemy_room_probability number  Per-cell probability a non-special room gets enemies. Range [0, 1].

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
    local total = sum + (n - 1) * theme.wall_thickness
    if total > MAP_SIZE then
        return false, "budget " .. total .. " > " .. MAP_SIZE .. " for distribution"
    end
    return true
end

--- Hard-error if any distribution in `theme` violates the budget constraint or
--- cell-dim minimum.
---@param theme ProcgenTheme
function themes.validate(theme)
    assert(theme.wall_thickness >= 1, "wall_thickness must be ≥ 1")
    assert(
        theme.wall_grow_probability >= 0 and theme.wall_grow_probability <= 1,
        "wall_grow_probability must be in [0, 1]"
    )
    assert(
        theme.off_screen_edge_probability >= 0 and theme.off_screen_edge_probability <= 1,
        "off_screen_edge_probability must be in [0, 1]"
    )
    assert(
        type(theme.enemy_room_probability) == "number"
        and theme.enemy_room_probability >= 0
        and theme.enemy_room_probability <= 1,
        "enemy_room_probability must be a number in [0, 1]"
    )
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
---@field col_walls integer[] Wall thickness after each column (length = #col_widths - 1).
---@field row_walls integer[] Wall thickness after each row (length = #row_heights - 1).
---@field border_left integer
---@field border_right integer
---@field border_top integer
---@field border_bottom integer

--- Roll wall thicknesses for one axis and derive the two border values from surplus.
---@param cell_sizes integer[]
---@param wall_thickness integer
---@param wall_grow_probability number
---@param rng RngInstance
---@return integer[] walls, integer border_lo, integer border_hi
local function roll_walls_and_border(cell_sizes, wall_thickness, wall_grow_probability, rng)
    local n = #cell_sizes
    local cell_sum = 0
    for _, v in ipairs(cell_sizes) do cell_sum = cell_sum + v end
    local surplus = MAP_SIZE - cell_sum - (n - 1) * wall_thickness
    local walls = {}
    for i = 1, n - 1 do
        walls[i] = wall_thickness
        if surplus > 0 and rng:rndf() < wall_grow_probability then
            walls[i] = walls[i] + 1
            surplus = surplus - 1
        end
    end
    local border_lo = math.floor(surplus / 2)
    local border_hi = surplus - border_lo
    return walls, border_lo, border_hi
end

--- Roll a macro-grid shape, per-axis cell-size distributions, wall thicknesses,
--- and derive border margins from remaining surplus.
---@param theme ProcgenTheme
---@param rng RngInstance
---@return ProcgenGrid
function themes.roll_grid(theme, rng)
    local shape = rng:choose_random_from_list(theme.grid_shapes)
    local w, h = shape[1], shape[2]
    local col_widths = rng:choose_random_from_list(theme.distributions[w])
    local row_heights = rng:choose_random_from_list(theme.distributions[h])
    local col_walls, border_left, border_right =
        roll_walls_and_border(col_widths, theme.wall_thickness, theme.wall_grow_probability, rng)
    local row_walls, border_top, border_bottom =
        roll_walls_and_border(row_heights, theme.wall_thickness, theme.wall_grow_probability, rng)
    return {
        col_widths   = col_widths,
        row_heights  = row_heights,
        col_walls    = col_walls,
        row_walls    = row_walls,
        border_left  = border_left,
        border_right = border_right,
        border_top   = border_top,
        border_bottom = border_bottom,
    }
end

themes.castle = {
    wall_thickness = 2,
    -- wall_grow_probability = 0.3,
    wall_grow_probability = 0,
    -- grid_shapes = { { 3, 3 }, { 2, 2 } },  -- 2x2 commented out until chunks authored
    grid_shapes = { { 3, 3 } },
    distributions = {
        [3] = { { 4, 3, 3 }, { 3, 4, 3 }, { 3, 3, 4 } },
        -- [2] = { { 6, 6 } },  -- 2x2 commented out until chunks authored
    },
    exit_width_weights = { [1] = 1, [2] = 3, [3] = 1 },
    extra_edge_probability = 0.2,
    off_screen_edge_probability = 0.15,
    target_deployment_distance = 5,
    enemy_room_probability = 0.4,
}

themes.cave = {
    wall_thickness = 2,
    -- wall_grow_probability = 0.5,
    wall_grow_probability = 0,
    grid_shapes = { { 3, 3 }, { 2, 2 } },
    distributions = {
        [3] = { { 4, 3, 3 }, { 3, 4, 3 }, { 3, 3, 4 } },
        [2] = { { 6, 6 } },
    },
    exit_width_weights = { [1] = 1, [2] = 3, [3] = 3, [4] = 1 },
    extra_edge_probability = 0.35,
    off_screen_edge_probability = 0.25,
    target_deployment_distance = 5,
    enemy_room_probability = 0.4,
}

themes.validate(themes.castle)
themes.validate(themes.cave)

return themes
