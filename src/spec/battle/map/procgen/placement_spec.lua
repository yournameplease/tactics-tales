require("src.spec.picotron_shim")

local luassert = require("luassert")
local placement = require("src.tactics.battle.map.procgen.placement")
local random    = require("src.tactics.util.random")

local function make_graph(adj)
    local edges = {}
    for a, neighbors in ipairs(adj) do
        for _, b in ipairs(neighbors) do
            if a < b then table.insert(edges, { a, b }) end
        end
    end
    return { edges = edges, adjacency = adj }
end

-- Linear chain 1-2-3-4. Graph poles are nodes 1 and 4.
local function chain4()
    return make_graph({ { 2 }, { 1, 3 }, { 2, 4 }, { 3 } })
end

-- Star: hub=1 connected to 2, 3, 4.
local function star4()
    return make_graph({ { 2, 3, 4 }, { 1 }, { 1 }, { 1 } })
end

describe("tactics.battle.map.procgen.placement", function()
    describe("select (kill_boss)", function()
        it("places deployment and boss at opposite poles", function()
            local g = chain4()
            local result = placement.select(g, "kill_boss", random.new(1))
            luassert.is_true(result.deployment_cell == 1 or result.deployment_cell == 4)
            luassert.is_true(result.boss_cell == 1 or result.boss_cell == 4)
            luassert.are_not_equal(result.deployment_cell, result.boss_cell)
        end)

        it("has no escape_cell", function()
            local result = placement.select(chain4(), "kill_boss", random.new(1))
            luassert.is_nil(result.escape_cell)
        end)
    end)

    describe("select (escape)", function()
        it("places deployment and escape_cell at opposite poles", function()
            local g = chain4()
            local result = placement.select(g, "escape", random.new(1))
            luassert.is_true(result.deployment_cell == 1 or result.deployment_cell == 4)
            luassert.is_true(result.escape_cell == 1 or result.escape_cell == 4)
            luassert.are_not_equal(result.deployment_cell, result.escape_cell)
        end)

        it("has no boss_cell", function()
            local result = placement.select(chain4(), "escape", random.new(1))
            luassert.is_nil(result.boss_cell)
        end)
    end)

    describe("select (rout)", function()
        it("places deployment at the hub of a star (min eccentricity, max degree)", function()
            -- Hub=1 has eccentricity 1 and degree 3; all spokes have eccentricity 2 and degree 1.
            local result = placement.select(star4(), "rout", random.new(1))
            luassert.are_equal(1, result.deployment_cell)
        end)

        it("returns no boss_cell or escape_cell", function()
            local result = placement.select(star4(), "rout", random.new(1))
            luassert.is_nil(result.boss_cell)
            luassert.is_nil(result.escape_cell)
        end)

        it("falls back to all nodes when no candidate has degree >= 2", function()
            -- Chain 1-2: both nodes have degree 1. Should still return a result.
            local g = make_graph({ { 2 }, { 1 } })
            local result = placement.select(g, "rout", random.new(1))
            luassert.is_not_nil(result.deployment_cell)
        end)
    end)

    describe("select (defend)", function()
        it("places deployment at the hub of a star (same logic as rout)", function()
            local result = placement.select(star4(), "defend", random.new(1))
            luassert.are_equal(1, result.deployment_cell)
        end)
    end)

    it("errors on unknown objective", function()
        luassert.has_error(function()
            placement.select(chain4(), "unknown", random.new(1))
        end)
    end)

    describe("enemy_cells", function()
        it("marks all non-special cells as enemy when probability = 1.0", function()
            -- chain4: kill_boss places deployment at one pole, boss at the other.
            -- The two middle cells (2 and 3) are non-special.
            local g = chain4()
            local theme = { target_deployment_distance = nil, enemy_room_probability = 1.0 }
            local result = placement.select(g, "kill_boss", random.new(1), theme)
            local specials = { [result.deployment_cell] = true, [result.boss_cell] = true }
            for node in pairs(g.adjacency) do
                if not specials[node] then
                    luassert.is_true(result.enemy_cells[node] == true,
                        "expected node " .. node .. " to be in enemy_cells")
                end
            end
        end)

        it("marks no cells as enemy when probability = 0.0", function()
            local g = chain4()
            local theme = { target_deployment_distance = nil, enemy_room_probability = 0.0 }
            local result = placement.select(g, "kill_boss", random.new(1), theme)
            local count = 0
            for _ in pairs(result.enemy_cells) do count = count + 1 end
            luassert.are_equal(0, count)
        end)

        it("never marks special cells as enemy", function()
            local g = chain4()
            local theme = { target_deployment_distance = nil, enemy_room_probability = 1.0 }
            local result = placement.select(g, "kill_boss", random.new(1), theme)
            luassert.is_nil(result.enemy_cells[result.deployment_cell])
            luassert.is_nil(result.enemy_cells[result.boss_cell])
        end)

        it("returns empty enemy_cells when theme is nil", function()
            local result = placement.select(chain4(), "kill_boss", random.new(1), nil)
            local count = 0
            for _ in pairs(result.enemy_cells) do count = count + 1 end
            luassert.are_equal(0, count)
        end)

        it("returns empty enemy_cells when theme has no enemy_room_probability", function()
            local theme = { target_deployment_distance = nil }
            local result = placement.select(chain4(), "kill_boss", random.new(1), theme)
            local count = 0
            for _ in pairs(result.enemy_cells) do count = count + 1 end
            luassert.are_equal(0, count)
        end)

        it("returns enemy_cells for escape objective", function()
            local g = chain4()
            local theme = { target_deployment_distance = nil, enemy_room_probability = 1.0 }
            local result = placement.select(g, "escape", random.new(1), theme)
            luassert.is_not_nil(result.enemy_cells)
            luassert.is_nil(result.enemy_cells[result.deployment_cell])
            luassert.is_nil(result.enemy_cells[result.escape_cell])
        end)

        it("returns enemy_cells for rout objective", function()
            local g = star4()
            local theme = { enemy_room_probability = 1.0 }
            local result = placement.select(g, "rout", random.new(1), theme)
            luassert.is_not_nil(result.enemy_cells)
            luassert.is_nil(result.enemy_cells[result.deployment_cell])
        end)

        describe("scatter mode", function()
            it("returns enemy_cells = nil for kill_boss", function()
                local g = chain4()
                local theme = { enemy_room_probability = 1.0 }
                local result = placement.select(g, "kill_boss", random.new(1), theme, "scatter")
                luassert.is_nil(result.enemy_cells)
            end)

            it("returns enemy_cells = nil for escape", function()
                local g = chain4()
                local theme = { enemy_room_probability = 1.0 }
                local result = placement.select(g, "escape", random.new(1), theme, "scatter")
                luassert.is_nil(result.enemy_cells)
            end)

            it("returns enemy_cells = nil for rout", function()
                local theme = { enemy_room_probability = 1.0 }
                local result = placement.select(star4(), "rout", random.new(1), theme, "scatter")
                luassert.is_nil(result.enemy_cells)
            end)

            it("returns enemy_cells = nil for defend", function()
                local theme = { enemy_room_probability = 1.0 }
                local result = placement.select(star4(), "defend", random.new(1), theme, "scatter")
                luassert.is_nil(result.enemy_cells)
            end)
        end)
    end)
end)
