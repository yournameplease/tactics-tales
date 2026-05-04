---@brief
--- Provides pathfinding capabilities for units on the battle map.
--- Uses Dijkstra's algorithm to find reachable tiles and calculate shortest paths
--- based on movement costs.

local point = require("src.tactics.util.point")
local array_2d = require("src.tactics.util.array_2d")
local lists = require("src.tactics.util.lists")

-- tile flags:
-- 0: empty.solid
-- 1-3: terrain type
-- 0 default
-- 1 forest
-- 2 sand
-- 3 hill
-- 4 mountain
-- 5 shallow water
-- 6 deep water
-- 7

---@class ShortestPathEntry
---@field cost integer Total movement cost from start to this tile.
---@field prev? Point Previous tile in the shortest path, nil for the start tile.

---@alias DistanceFunction fun(tile: Point): integer

---@class ShortestPathQueueEntry
---@field cost integer
---@field x integer
---@field y integer

-- cost to move onto x,y from any neighbor
---@param map BattleMap
---@param tile Point
---@param movement_side string
---@return integer
local function movement_cost(map, tile, movement_side)
    local terrain = map:get_terrain(tile)
    if terrain == nil then return 999 end

    local unit = map:get_at_tile(tile)
    if unit ~= nil then
        if unit.movement_side ~= movement_side then return 999 end
    end

    if terrain.solid then return 999 end
    return terrain.movement_cost
end


-- Shared neighbor offsets (up, down, left, right)
local NEIGHBORS = { {x=0, y=1}, {x=0, y=-1}, {x=1, y=0}, {x=-1, y=0} }

---@param map BattleMap
---@param movement_side string
---@return DistanceFunction
local function distance_for_unit(map, movement_side)
    return function(tile)
        return movement_cost(map, tile, movement_side)
    end
end

---@desc
--- Returns the shortest path to all reachable tiles, up to a maximum cost.
--- Each tile will also contain a field for the previous tile in the shortest path.
---@param start_x integer
---@param start_y integer
---@param distance_function DistanceFunction
---@param max_cost integer
---@param max_point Point Upper-right boundary (exclusive) of the traversable area.
---@return Array2D
local function _dijkstra_traversal(start_x, start_y, distance_function, max_cost, max_point)
    -- The output map containing cost and parent info for every visited node
    log.trace("doing Dijkstra: ", start_x, start_y, max_point)
    local visited_info = array_2d.new(max_point.x, max_point.y)

    -- Initialize
    ---@type ShortestPathQueueEntry[]
    local priority_queue = {}

    -- Start node setup
    local start_cost = 0 -- Cost to be at the start is 0

    visited_info:set(start_x, start_y, { cost = start_cost, prev = nil })
    table.insert(priority_queue, {x = start_x, y = start_y, cost = start_cost})

    -- Main Loop
    while #priority_queue > 0 do
        -- 1. Pop the node with the lowest cost
        local min_node_cost = 999
        local min_index = -1

        for i, node in ipairs(priority_queue) do
            if node.cost < min_node_cost then
                min_node_cost = node.cost
                min_index = i
            end
        end

        local u = table.remove(priority_queue, min_index)
        local ux, uy, ucost = u.x, u.y, u.cost

        log.trace("Processing shortest path point", ux, uy, ucost)
        -- 2. Check if we found a better path to this node already
        -- (Standard Dijkstra laziness check)
        local current_info = visited_info:get(ux, uy)
        if current_info and ucost <= current_info.cost then

            -- 3. Explore neighbors
            for _, offset in ipairs(NEIGHBORS) do
                local vx, vy = ux + offset.x, uy + offset.y

                -- Calculate cost to move FROM u INTO v
                local move_cost = 0
                if vx >= 0 and vx < max_point.x and vy >= 0 and vy < max_point.y then
                    move_cost = distance_function(point.of(vx, vy))
                else
                    move_cost = 999
                end
                assert(move_cost > 0, "0 cost moves not yet implemented.")

                -- Only proceed if the tile is traversable (movement_cost returns 999 for blocked)
                if move_cost < 999 then
                    local new_total = ucost + move_cost

                    -- 4. Check limits
                    if new_total <= max_cost then
                        local neighbor_info = visited_info:get(vx, vy)

                        -- 5. Relaxation: Is this new path better than the old one?
                        if not neighbor_info or new_total < neighbor_info.cost then
                            -- Record the new cost and the tile we came from (ux, uy)
                            visited_info:set(vx, vy, { cost = new_total, prev = point.of(ux, uy) })
                            table.insert(priority_queue, {x = vx, y = vy, cost = new_total})
                        end
                    end
                end
            end
        end
    end

    return visited_info
end

-- --------------------------------------------------------------------------
-- Public API
-- --------------------------------------------------------------------------

local pathfinding = {
}

--- Calculates the cost and shortest path to ALL reachable tiles.
---@param map BattleMap
---@param start_x integer
---@param start_y integer
---@param movement_side string Side identifier used to determine unit passability.
---@param max_limit integer Maximum movement cost; tiles beyond this are unreachable.
---@return Array2D Sparse 2D map where each entry is a ShortestPathEntry.
function pathfinding.calculate_all_tile_costs(map, start_x, start_y, movement_side, max_limit)
    local limit = max_limit or 99999
    return _dijkstra_traversal(start_x, start_y, distance_for_unit(map, movement_side), limit, point.of(map.width, map.height))
end

--- Reconstructs the path from the start tile to the given target tile.
---@param all_tile_costs Array2D Costs map from calculate_all_tile_costs.
---@param tile Point Destination tile.
---@return Point[] List of points from start to tile (inclusive).
function pathfinding.get_path_to_tile(all_tile_costs, tile)
    assert(all_tile_costs:get_point(tile) ~= nil)
    local path = {}
    table.insert(path, tile:copy())
    local next_tile = tile
    while all_tile_costs:get_point(next_tile).prev ~= nil do
        next_tile = all_tile_costs:get_point(next_tile).prev
        table.insert(path, next_tile:copy())
    end
    return lists.do_reverse(path)
end

--- Finds all tiles reachable from a starting point within a given total cost.
---@param map BattleMap
---@param start_x integer
---@param start_y integer
---@param movement_side string Side identifier used to determine unit passability.
---@param total_cost integer Maximum movement cost budget.
---@return Array2D Sparse 2D map where reachable[x][y] = true.
function pathfinding.find_reachable_tiles(map, start_x, start_y, movement_side, total_cost)
    -- 1. Get the detailed map from the core engine
    local full_map = _dijkstra_traversal(start_x, start_y, distance_for_unit(map, movement_side), total_cost, point.of(map.width, map.height))

    -- 2. Transform it into the simple boolean map expected by existing code
    local reachable = array_2d.new(full_map.w, full_map.h, false)

    full_map:foreachpoint(
        function (tile, value)
            -- We don't need to check cost <= total_cost here because
            -- the core engine already filtered by total_cost.
            -- TODO: not positive after refactor to array_2d.Array2D.  investigate.
            if (value.cost <= total_cost) then
                reachable:set_point(tile, true)
            end
        end
    )

    return reachable
end

---@desc
--- Extends an existing path towards a new target tile.
--- If the target is not immediately reachable, this function will backtrack
--- along the given path until the target is within movement range,
--- then calculate and append the new segment to create a valid path.
--- legal_tiles should be 1 for reachable tiles and 0 otherwise
---@param path Point[] Current path as a list of points.
---@param target Point Destination tile to extend towards.
---@param max_length integer Maximum number of steps from the start tile.
---@param legal_tiles userdata Bitfield where value 1 marks traversable tiles.
---@return Point[]
function pathfinding.extend_path_to_point(path, target, max_length, legal_tiles)
    if legal_tiles:get(target.x, target.y) == 0 then
        return path
    end
    if path[#path] == target then
        return path
    end

    log.trace("Extend path")
    log.trace("Extend path", #path, target, max_length)

    local distance = function(tile)
        return (legal_tiles:get(tile.x, tile.y) & 1 ~= 0) and 1 or 999
    end
    local extend_path = function(current_path, t, full_map)
        local new_points = { t }
        log.trace("Extending path!", t)
        while (full_map:get_point(new_points[#new_points]).prev ~= current_path[#current_path]) do
            local prev = full_map:get_point(new_points[#new_points]).prev
            table.insert(new_points, prev)
        end
        -- TODO: config
        local visited = array_2d.new(legal_tiles:width(), legal_tiles:height(), false)
        for _,p in ipairs(current_path) do
            visited:set_point(p, true)
        end
        while #new_points > 0 do
            local next_point = table.remove(new_points)
            if visited:get_point(next_point) then
                while current_path[#current_path] ~= next_point do
                    table.remove(current_path)
                end
            else
                visited:set_point(next_point, true)
                table.insert(current_path, next_point:copy())
                if current_path[#current_path] == t then
                    return current_path
                end
            end
        end
        return current_path
    end

    for i,p in ipairs(path) do
        if p == target then
            local out = {}
            for j=1,i do
                table.insert(out, path[j]:copy())
            end
            return out
        end
    end

    -- TODO: config
    local max_tile = point.of(16, 16)

    while #path > max_length + 1 do
        table.remove(path)
    end
    while #path > 0 do
        local start = path[#path]
        local remaining_length = max_length + 1 - #path
        local full_map = _dijkstra_traversal(start.x, start.y, distance, remaining_length, point.of(legal_tiles:width(), legal_tiles:height()))
        if full_map:get_point(target) ~= nil and full_map:get_point(target).cost <= remaining_length then
            return extend_path(path, target, full_map)
        end
        table.remove(path)
    end
    do
        local start = path[1]
        local remaining_length = max_length
        local full_map = _dijkstra_traversal(start.x, start.y, distance, remaining_length, max_tile)
        if full_map:get_point(target).cost <= remaining_length then
            return extend_path(path, target, full_map)
        end
    end
    return path
end

return pathfinding
