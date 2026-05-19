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
end)
