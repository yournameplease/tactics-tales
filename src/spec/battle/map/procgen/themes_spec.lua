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
        wall_grow_probability = 0,
        grid_shapes = { { 3, 3 }, { 2, 2 } },
        distributions = {
            [3] = { { 3, 4, 3 } },
            [2] = { { 6, 6 } },
        },
        exit_width_weights = { [1] = 1 },
        extra_edge_probability = 0,
        off_screen_edge_probability = 0,
        enemy_room_probability = 0.4,
    }
    for k, v in pairs(opts or {}) do t[k] = v end
    return t
end

describe("tactics.battle.map.procgen.themes", function()
    describe("validate", function()
        it("accepts a theme whose distributions satisfy the budget constraint", function()
            luassert.has_no.errors(function() themes.validate(make_theme()) end)
        end)

        it("rejects a distribution whose minimum total exceeds MAP_SIZE", function()
            -- {5,5,5} + 2 walls*2 = 19 > 16
            local theme = make_theme({
                distributions = { [3] = { { 5, 5, 5 } }, [2] = { { 6, 6 } } },
            })
            luassert.has_error(function() themes.validate(theme) end)
        end)

        it("accepts a distribution with surplus (border is derived at roll time)", function()
            -- {3,3,3} + 2 walls*2 = 13 <= 16: valid, surplus becomes border
            local theme = make_theme({
                distributions = { [3] = { { 3, 3, 3 } }, [2] = { { 6, 6 } } },
            })
            luassert.has_no.errors(function() themes.validate(theme) end)
        end)

        it("rejects wall_grow_probability outside [0, 1]", function()
            luassert.has_error(function()
                themes.validate(make_theme({ wall_grow_probability = 1.5 }))
            end)
            luassert.has_error(function()
                themes.validate(make_theme({ wall_grow_probability = -0.1 }))
            end)
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

        it("rejects enemy_room_probability outside [0, 1]", function()
            luassert.has_error(function()
                themes.validate(make_theme({ enemy_room_probability = 1.5 }))
            end)
            luassert.has_error(function()
                themes.validate(make_theme({ enemy_room_probability = -0.1 }))
            end)
        end)

        it("accepts enemy_room_probability of 0 and 1", function()
            luassert.has_no.errors(function()
                themes.validate(make_theme({ enemy_room_probability = 0 }))
            end)
            luassert.has_no.errors(function()
                themes.validate(make_theme({ enemy_room_probability = 1 }))
            end)
        end)
    end)

    describe("castle theme", function()
        it("validates", function()
            luassert.has_no.errors(function() themes.validate(themes.castle) end)
        end)
    end)

    -- describe("cave theme", function()  -- cave commented out until chunks authored
    --     it("validates", function()
    --         luassert.has_no.errors(function() themes.validate(themes.cave) end)
    --     end)
    -- end)

    describe("roll_grid", function()
        it("returns col_widths and row_heights drawn from the theme's distributions", function()
            local rng = random.new(42)
            local theme = make_theme()

            local grid = themes.roll_grid(theme, rng)

            luassert.are_same({ 3, 4, 3 }, grid.col_widths)
            luassert.are_same({ 3, 4, 3 }, grid.row_heights)
        end)

        it("returns col_walls and row_walls of the correct length", function()
            local rng = random.new(42)
            local grid = themes.roll_grid(make_theme(), rng)

            luassert.are_equal(#grid.col_widths - 1, #grid.col_walls)
            luassert.are_equal(#grid.row_heights - 1, #grid.row_walls)
        end)

        it("grid geometry totals MAP_SIZE per axis across 20 rolls", function()
            local rng = random.new(1234)
            local theme = themes.castle
            for _ = 1, 20 do
                local grid = themes.roll_grid(theme, rng)
                local function axis_total(cells, walls, border_lo, border_hi)
                    local s = border_lo + border_hi
                    for _, v in ipairs(cells) do s = s + v end
                    for _, v in ipairs(walls) do s = s + v end
                    return s
                end
                luassert.are_equal(16, axis_total(grid.col_widths, grid.col_walls, grid.border_left, grid.border_right))
                luassert.are_equal(16, axis_total(grid.row_heights, grid.row_walls, grid.border_top, grid.border_bottom))
            end
        end)

        it("wall_grow_probability=0 produces walls all at minimum thickness", function()
            local rng = random.new(99)
            local theme = make_theme({ wall_grow_probability = 0 })
            local grid = themes.roll_grid(theme, rng)

            for _, w in ipairs(grid.col_walls) do
                luassert.are_equal(theme.wall_thickness, w)
            end
            for _, w in ipairs(grid.row_walls) do
                luassert.are_equal(theme.wall_thickness, w)
            end
        end)
    end)
end)
