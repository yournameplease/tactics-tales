require("src.spec.picotron_shim")

local luassert = require("luassert")

local graph = require("src.tactics.battle.map.procgen.graph")
local random = require("src.tactics.util.random")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Check that every cell in a W×H grid is reachable from cell index 1 via the
--- graph's adjacency.
---@param g { adjacency: integer[][] }
---@param w integer
---@param h integer
---@return boolean
local function is_connected(g, w, h)
    local n = w * h
    local seen = { [1] = true }
    local stack = { 1 }
    while #stack > 0 do
        local cur = table.remove(stack)
        for _, neighbor in ipairs(g.adjacency[cur] or {}) do
            if not seen[neighbor] then
                seen[neighbor] = true
                table.insert(stack, neighbor)
            end
        end
    end
    for i = 1, n do
        if not seen[i] then return false end
    end
    return true
end

local function make_theme(extra_edge_probability)
    return { extra_edge_probability = extra_edge_probability or 0 }
end

describe("tactics.battle.map.procgen.graph", function()
    describe("generate", function()
        it("returns a fully connected graph on a 2x2 grid", function()
            local rng = random.new(1)
            local g = graph.generate(make_theme(0), 2, 2, rng)
            luassert.is_true(is_connected(g, 2, 2))
        end)

        it("produces fully connected graphs for every shape up to 3x3", function()
            for w = 1, 3 do
                for h = 1, 3 do
                    for seed = 1, 10 do
                        local rng = random.new(seed)
                        local g = graph.generate(make_theme(0), w, h, rng)
                        luassert.is_true(is_connected(g, w, h),
                            "disconnected for w=" .. w .. " h=" .. h .. " seed=" .. seed)
                    end
                end
            end
        end)

        it("returns exactly W*H - 1 edges when extra_edge_probability is 0 (spanning tree)", function()
            local rng = random.new(7)
            local g = graph.generate(make_theme(0), 3, 3, rng)
            luassert.are_equal(8, #g.edges)
        end)

        it("adds edges beyond the spanning tree when extra_edge_probability is 1", function()
            local rng = random.new(7)
            local g = graph.generate(make_theme(1), 3, 3, rng)
            -- 3x3 grid has 12 possible adjacent pairs (6 horizontal + 6 vertical).
            -- With p=1 every adjacency becomes an edge.
            luassert.are_equal(12, #g.edges)
        end)

        it("returns edges as {a, b} pairs with a < b", function()
            local rng = random.new(3)
            local g = graph.generate(make_theme(0), 2, 2, rng)
            for _, edge in ipairs(g.edges) do
                luassert.is_true(edge[1] < edge[2])
            end
        end)
    end)

    describe("bridges", function()
        it("returns every edge of a tree as a bridge", function()
            local rng = random.new(2)
            local g = graph.generate(make_theme(0), 3, 3, rng)
            local bridges = graph.bridges(g)
            luassert.are_equal(#g.edges, #bridges)
        end)

        it("returns no bridges for a fully cyclic 2x2 grid", function()
            local rng = random.new(2)
            local g = graph.generate(make_theme(1), 2, 2, rng)
            -- 2x2 has 4 edges total (2 horizontal + 2 vertical), forming a cycle.
            local bridges = graph.bridges(g)
            luassert.are_equal(0, #bridges)
        end)
    end)
end)
