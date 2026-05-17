require("src.spec.picotron_shim")

local luassert = require("luassert")

local themes = require("src.tactics.battle.map.procgen.themes")
local random = require("src.tactics.util.random")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a minimal valid theme, overriding any fields given in opts.
---@param opts table?
---@return ProcgenTheme
local function make_theme(opts)
    local t = {
        wall_thickness = 2,
        border_margin = 1,
        grid_shapes = { { 3, 3 }, { 2, 2 } },
        distributions = {
            [3] = { { 3, 4, 3 } },
            [2] = { { 6, 6 } },
        },
        exit_width_weights = { [1] = 1 },
        extra_edge_probability = 0,
    }
    for k, v in pairs(opts or {}) do t[k] = v end
    return t
end

describe("tactics.battle.map.procgen.themes", function()
    describe("validate", function()
        it("accepts a theme whose distributions satisfy the budget constraint", function()
            luassert.has_no.errors(function() themes.validate(make_theme()) end)
        end)

        it("rejects a distribution whose budget does not total 16", function()
            local theme = make_theme({
                distributions = { [3] = { { 3, 3, 3 } }, [2] = { { 6, 6 } } },
            })
            luassert.has_error(function() themes.validate(theme) end)
        end)

        it("rejects a distribution with a cell smaller than 3 tiles", function()
            local theme = make_theme({
                distributions = { [3] = { { 2, 5, 3 } }, [2] = { { 6, 6 } } },
            })
            luassert.has_error(function() themes.validate(theme) end)
        end)

        it("rejects a distribution whose length does not match the cell count", function()
            local theme = make_theme({
                distributions = { [3] = { { 3, 4, 3, 0 } }, [2] = { { 6, 6 } } },
            })
            luassert.has_error(function() themes.validate(theme) end)
        end)
    end)

    describe("castle theme", function()
        it("validates", function()
            luassert.has_no.errors(function() themes.validate(themes.castle) end)
        end)
    end)

    describe("cave theme", function()
        it("validates", function()
            luassert.has_no.errors(function() themes.validate(themes.cave) end)
        end)
    end)

    describe("roll_grid", function()
        it("returns col_widths and row_heights drawn from the theme's distributions", function()
            local rng = random.new(42)
            local theme = make_theme()

            local grid = themes.roll_grid(theme, rng)

            luassert.are_same({ 3, 4, 3 }, grid.col_widths)
            luassert.are_same({ 3, 4, 3 }, grid.row_heights)
        end)

        it("produces a grid that satisfies the budget constraint", function()
            local rng = random.new(1234)
            local theme = themes.castle
            for _ = 1, 20 do
                local grid = themes.roll_grid(theme, rng)
                local function check(dist)
                    local sum = 0
                    for _, v in ipairs(dist) do sum = sum + v end
                    return sum + (#dist - 1) * theme.wall_thickness + 2 * theme.border_margin
                end
                luassert.are_equal(16, check(grid.col_widths))
                luassert.are_equal(16, check(grid.row_heights))
            end
        end)
    end)
end)
