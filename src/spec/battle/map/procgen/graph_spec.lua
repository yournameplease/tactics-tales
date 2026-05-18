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

    describe("node_depths", function()
        -- Helper: build a ConnectionGraph directly from an adjacency list.
        -- `adj` is a table: node_index -> {neighbor, ...}
        local function make_graph(adj)
            local edges = {}
            for a, neighbors in ipairs(adj) do
                for _, b in ipairs(neighbors) do
                    if a < b then table.insert(edges, { a, b }) end
                end
            end
            return { edges = edges, adjacency = adj }
        end

        it("returns depth 0 for all nodes in a single-node graph", function()
            local g = make_graph({ {} })
            local depths = graph.node_depths(g, 1)
            luassert.are_equal(0, depths[1])
        end)

        it("assigns depth 0 to the node furthest from start on a linear chain", function()
            -- Chain: 1-2-3-4. Start=1, furthest=4 (depth 0), then depths from 4.
            local g = make_graph({ { 2 }, { 1, 3 }, { 2, 4 }, { 3 } })
            local depths = graph.node_depths(g, 1)
            luassert.are_equal(3, depths[1])
            luassert.are_equal(2, depths[2])
            luassert.are_equal(1, depths[3])
            luassert.are_equal(0, depths[4])
        end)

        it("gives depth 2 to the middle of a 5-node chain regardless of which end is chosen", function()
            -- Chain: 1-2-3-4-5. Start=3. Both ends are equidistant from 3.
            -- BFS from whichever end is chosen, node 3 is always 2 hops away.
            local g = make_graph({ { 2 }, { 1, 3 }, { 2, 4 }, { 3, 5 }, { 4 } })
            local depths = graph.node_depths(g, 3)
            luassert.are_equal(2, depths[3])
        end)

        it("counts steps correctly on a star graph (hub with 3 spokes)", function()
            -- Star: hub=1 connected to 2,3,4. Start=2.
            -- Furthest from 2 is 3 or 4 (both distance 2). BFS from that spoke gives:
            -- spoke: 0, hub: 1, other spokes: 2, start-spoke: 2.
            local g = make_graph({ { 2, 3, 4 }, { 1 }, { 1 }, { 1 } })
            local depths = graph.node_depths(g, 2)
            -- depth[2] (start) should be 2 (two hops from the chosen far spoke).
            luassert.are_equal(2, depths[2])
            -- hub (node 1) is one hop from any spoke.
            luassert.are_equal(1, depths[1])
        end)
    end)

    describe("roll_offscreen_edges", function()
        local function make_offscreen_theme(prob)
            return { off_screen_edge_probability = prob }
        end

        it("returns empty list with probability 0", function()
            local rng = random.new(1)
            local result = graph.roll_offscreen_edges(make_offscreen_theme(0), 3, 3, rng)
            luassert.are_equal(0, #result)
        end)

        it("returns all border faces with probability 1 on a 2x2 grid (8 entries)", function()
            local rng = random.new(1)
            local result = graph.roll_offscreen_edges(make_offscreen_theme(1), 2, 2, rng)
            -- 2 north + 2 south + 2 west + 2 east = 8
            luassert.are_equal(8, #result)
        end)

        it("returns all border faces with probability 1 on a 3x3 grid (12 entries)", function()
            local rng = random.new(1)
            local result = graph.roll_offscreen_edges(make_offscreen_theme(1), 3, 3, rng)
            -- 3 north + 3 south + 3 west + 3 east = 12
            luassert.are_equal(12, #result)
        end)

        it("each result has cell_index and face fields", function()
            local rng = random.new(1)
            local result = graph.roll_offscreen_edges(make_offscreen_theme(1), 2, 2, rng)
            for _, oe in ipairs(result) do
                luassert.is_not_nil(oe.cell_index)
                luassert.is_not_nil(oe.face)
            end
        end)

        it("only produces valid faces (north/south/east/west)", function()
            local rng = random.new(1)
            local result = graph.roll_offscreen_edges(make_offscreen_theme(1), 3, 3, rng)
            local valid = { north = true, south = true, east = true, west = true }
            for _, oe in ipairs(result) do
                luassert.is_true(valid[oe.face] ~= nil,
                    "unexpected face '" .. tostring(oe.face) .. "'")
            end
        end)

        it("cell_index values are in range [1, W*H]", function()
            local rng = random.new(1)
            local result = graph.roll_offscreen_edges(make_offscreen_theme(1), 3, 3, rng)
            for _, oe in ipairs(result) do
                luassert.is_true(oe.cell_index >= 1 and oe.cell_index <= 9,
                    "cell_index " .. oe.cell_index .. " out of [1,9]")
            end
        end)

        it("corner cells do not appear twice for the same face", function()
            -- Cell 1 (col=1, row=1) should appear as 'north' and 'west' but not north twice.
            local rng = random.new(1)
            local result = graph.roll_offscreen_edges(make_offscreen_theme(1), 3, 3, rng)
            local seen = {}
            for _, oe in ipairs(result) do
                local key = oe.cell_index .. ":" .. oe.face
                luassert.is_nil(seen[key], "duplicate entry " .. key)
                seen[key] = true
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
