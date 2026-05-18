---@brief
--- Coordinate helpers for mapping ProcgenGrid cells to map-space positions.

local grid_layout = {}

--- Map x-coordinate where cell column `col` interior starts (1-based).
---@param grid ProcgenGrid
---@param col integer
---@return integer
function grid_layout.cell_x_start(grid, col)
    local x = grid.border_left + 1
    for c = 1, col - 1 do
        x = x + grid.col_widths[c] + grid.col_walls[c]
    end
    return x
end

--- Map y-coordinate where cell row `row` interior starts (1-based).
---@param grid ProcgenGrid
---@param row integer
---@return integer
function grid_layout.cell_y_start(grid, row)
    local y = grid.border_top + 1
    for r = 1, row - 1 do
        y = y + grid.row_heights[r] + grid.row_walls[r]
    end
    return y
end

--- Convert an ExitZone from chunk border coordinates to map coordinates.
--- `cell_start` is the map coordinate of the cell interior start on the relevant axis.
---@param zone ExitZone?
---@param cell_start integer
---@return ExitZone?
function grid_layout.zone_to_map(zone, cell_start)
    if not zone then return nil end
    return { min = cell_start + zone.min - 2, max = cell_start + zone.max - 2 }
end

return grid_layout
