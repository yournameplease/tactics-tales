---@brief
--- Canonical sprite index constants and flag setup for integration tests.
--- Call setup() once per test suite (e.g., from BattleHarness.new or a before_all).

local M = {}

--- Passable floor tile: flag bit 0 clear. Terrain defaults to index 0 (movement_cost=1).
M.FLOOR = 1
--- Impassable solid tile: flag bit 0 set, blocked by pathfinder.
M.SOLID = 2

--- Set sprite flags for FLOOR and SOLID. Idempotent — safe to call multiple times.
function M.setup()
    fset(M.FLOOR, 0, false)
    fset(M.SOLID, 0, true)
end

return M
