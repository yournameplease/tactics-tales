---@brief
--- Canonical sprite index constants and flag setup for integration tests.
--- Call setup() once per test suite (e.g., from BattleHarness.new or a before_all).

local M = {}

--- Passable floor tile: flags 0x00, not solid, terrain type 0, movement cost 1.
M.FLOOR = 1
--- Impassable solid tile: flags 0x01, solid bit set, movement cost 999.
M.SOLID = 2

--- Set sprite flags for FLOOR and SOLID. Idempotent — safe to call multiple times.
function M.setup()
    fset(M.FLOOR, 0, false)
    fset(M.SOLID, 0, true)
end

return M
