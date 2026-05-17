---@brief
--- Connection-graph generation and bridge detection for procgen maps.
--- See docs/specs/procgen-map-spec.md §3.3 and §5.5.

---@class ConnectionGraph
---@field edges integer[][] List of `{a, b}` edges with a < b. Endpoints are 1-based cell indices.
---@field adjacency integer[][] Map of cell index -> list of neighbor cell indices.

local graph = {}

--- Convert a (col, row) pair (1-based) to a flat cell index.
---@param col integer
---@param row integer
---@param w integer
---@return integer
local function cell_index(col, row, w)
    return (row - 1) * w + col
end

--- All adjacent cell pairs in a W×H grid as `{a, b}` edges with a < b.
---@param w integer
---@param h integer
---@return integer[][]
local function all_adjacencies(w, h)
    local edges = {}
    for row = 1, h do
        for col = 1, w do
            local i = cell_index(col, row, w)
            if col < w then table.insert(edges, { i, cell_index(col + 1, row, w) }) end
            if row < h then table.insert(edges, { i, cell_index(col, row + 1, w) }) end
        end
    end
    return edges
end

--- In-place Fisher-Yates shuffle using `rng`.
---@param list any[]
---@param rng RngInstance
local function shuffle(list, rng)
    for i = #list, 2, -1 do
        local j = rng:rndi(i) + 1
        list[i], list[j] = list[j], list[i]
    end
end

---@param parents integer[]
---@param x integer
---@return integer
local function uf_find(parents, x)
    while parents[x] ~= x do
        parents[x] = parents[parents[x]]
        x = parents[x]
    end
    return x
end

--- Build the adjacency table from an edge list and cell count.
---@param edges integer[][]
---@param n integer Total cell count.
---@return integer[][]
local function build_adjacency(edges, n)
    local adj = {}
    for i = 1, n do adj[i] = {} end
    for _, e in ipairs(edges) do
        table.insert(adj[e[1]], e[2])
        table.insert(adj[e[2]], e[1])
    end
    return adj
end

--- Generate a random spanning tree over the W×H cell grid plus extra edges
--- rolled at `theme.extra_edge_probability` per adjacent pair.
---@param theme { extra_edge_probability: number }
---@param w integer
---@param h integer
---@param rng RngInstance
---@return ConnectionGraph
function graph.generate(theme, w, h, rng)
    local n = w * h
    local candidates = all_adjacencies(w, h)
    shuffle(candidates, rng)

    local parents = {}
    for i = 1, n do parents[i] = i end

    local edges = {}
    local extras = {}
    for _, e in ipairs(candidates) do
        local ra, rb = uf_find(parents, e[1]), uf_find(parents, e[2])
        if ra ~= rb then
            parents[ra] = rb
            table.insert(edges, e)
        else
            table.insert(extras, e)
        end
    end

    -- Extra-edge roll: a roll < threshold accepts the edge. rndi(1000) returns
    -- a uniform integer in [0, 999], so threshold = probability * 1000.
    local threshold = math.floor(theme.extra_edge_probability * 1000)
    for _, e in ipairs(extras) do
        if rng:rndi(1000) < threshold then
            table.insert(edges, e)
        end
    end

    return {
        edges = edges,
        adjacency = build_adjacency(edges, n),
    }
end

--- BFS distances from `start` to all reachable nodes.
---@param g ConnectionGraph
---@param start integer
---@return integer[] distances keyed by node index (unreachable nodes absent)
local function bfs_distances(g, start)
    local dist = { [start] = 0 }
    local queue = { start }
    local head = 1
    while head <= #queue do
        local cur = queue[head]; head = head + 1
        for _, neighbor in ipairs(g.adjacency[cur] or {}) do
            if dist[neighbor] == nil then
                dist[neighbor] = dist[cur] + 1
                table.insert(queue, neighbor)
            end
        end
    end
    return dist
end

--- Compute per-node depths as distance from the node farthest from `start`.
--- Runs BFS twice: once to find the farthest node, then from that node.
---@param g ConnectionGraph
---@param start integer Starting node (e.g. deployment cell).
---@return integer[] depths keyed by 1-based cell index
function graph.node_depths(g, start)
    local d1 = bfs_distances(g, start)
    local far = start
    for node, dist in pairs(d1) do
        if dist > d1[far] then far = node end
    end
    return bfs_distances(g, far)
end

--- Return the subset of `g.edges` whose removal disconnects the graph.
---@param g ConnectionGraph
---@return integer[][]
function graph.bridges(g)
    local n = 0
    for k in pairs(g.adjacency) do
        if k > n then n = k end
    end

    local function connected_without(skip_a, skip_b)
        local seen = { [1] = true }
        local stack = { 1 }
        local count = 1
        while #stack > 0 do
            local cur = table.remove(stack)
            for _, neighbor in ipairs(g.adjacency[cur]) do
                local edge_skipped = (cur == skip_a and neighbor == skip_b)
                    or (cur == skip_b and neighbor == skip_a)
                if not edge_skipped and not seen[neighbor] then
                    seen[neighbor] = true
                    count = count + 1
                    table.insert(stack, neighbor)
                end
            end
        end
        return count == n
    end

    local result = {}
    for _, e in ipairs(g.edges) do
        if not connected_without(e[1], e[2]) then
            table.insert(result, e)
        end
    end
    return result
end

return graph
