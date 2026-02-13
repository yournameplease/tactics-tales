---@brief
--- Provides pathfinding capabilities for units on the battle map.
--- Uses Dijkstra's algorithm to find reachable tiles and calculate shortest paths
--- based on movement costs.

local point = require("src.tactics.util.point")
local Point = point.Point
local Side = require("src.tactics.character.object.character").Side
local array_2d = require("src.tactics.util.array_2d")
local lists = require("src.tactics.util.lists")
local bm = require("src.tactics.battle.battle_map")

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

-- cost to move onto x,y from any neighbor
local function movement_cost(map: bm.BattleMap, tile: Point, side: Side): integer
    local terrain = map:get_terrain(tile)
    if terrain == nil then return 999 end

    local unit = map:get_at_tile(tile)
    if unit ~= nil then
        if unit.side ~= side then return 999 end
    end

    if terrain.solid then return 999 end
    return terrain.movement_cost
end


-- Shared neighbor offsets (up, down, left, right)
local NEIGHBORS = { {x=0, y=1}, {x=0, y=-1}, {x=1, y=0}, {x=-1, y=0} }

local record ShortestPathEntry
    cost: integer
    prev: Point
end

local type DistanceFunction = function(tile: Point): integer
local function distance_for_unit(map: bm.BattleMap, side: Side): DistanceFunction
    return function(tile: Point): integer
        return movement_cost(map, tile, side)
    end
end

---@desc
--- Returns the shortest path to all reachable tiles, up to a maximum cost.
--- Each tile will also contain a field for the previous tile in the shortest path.
local function _dijkstra_traversal(start_x: integer, start_y: integer, distance_function: DistanceFunction, max_cost: integer, max_point: Point): array_2d.Array2D<ShortestPathEntry>
    -- The output map containing cost and parent info for every visited node
    log.trace("doing Dijkstra: ", start_x, start_y, max_point)
    local visited_info: array_2d.Array2D<ShortestPathEntry> = array_2d.new(max_point.x, max_point.y)

    local record ShortestPathQueueEntry
        cost: integer
        x: integer
        y: integer
    end

    -- Initialize
    local priority_queue: { ShortestPathQueueEntry } = {}

    -- Start node setup
    local start_cost = 0 -- Cost to be at the start is 0

    visited_info:set(start_x, start_y, { cost = start_cost, prev = nil })
    pt.add(priority_queue, {x = start_x, y = start_y, cost = start_cost})

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

        local u = pt.deli(priority_queue, min_index)
        assert(u is ShortestPathQueueEntry)
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
                    move_cost = distance_function({ x=vx, y=vy })
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
                            pt.add(priority_queue, {x = vx, y = vy, cost = new_total})
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
    ShortestPathEntry = ShortestPathEntry
}

--- Calculates the cost and shortest path to ALL reachable tiles.
-- @return A table where map[x][y] = { cost = number, prev = {x, y} }
function pathfinding.calculate_all_tile_costs(map: bm.BattleMap, start_x: integer, start_y: integer, side: Side, max_limit: integer): array_2d.Array2D<ShortestPathEntry>
    local limit = max_limit or 99999
    return _dijkstra_traversal(start_x, start_y, distance_for_unit(map, side), limit, point.of(map.width, map.height))
end 

-- @return list of { { x, y } } tile coordinates from start position
function pathfinding.get_path_to_tile(all_tile_costs: array_2d.Array2D<ShortestPathEntry>, tile: Point): { Point } -- could be static with current signature
    assert(all_tile_costs:get_point(tile) ~= nil)
    local path: {Point} = {}
    pt.add(path, tile:copy())
    local next_tile = tile
    while all_tile_costs:get_point(next_tile).prev ~= nil do
        next_tile = all_tile_costs:get_point(next_tile).prev
        pt.add(path, next_tile:copy())
    end
    return lists.do_reverse(path)
end

--- Finds all tiles reachable from a starting point within a given total cost.
-- @return A table where reachable[x][y] = true (Compatible with original signature)
function pathfinding.find_reachable_tiles(map: bm.BattleMap, start_x: integer, start_y: integer, side: Side, total_cost: integer): array_2d.Array2D<boolean>
    -- 1. Get the detailed map from the core engine
    local full_map = _dijkstra_traversal(start_x, start_y, distance_for_unit(map, side), total_cost, point.of(map.width, map.height))

    -- 2. Transform it into the simple boolean map expected by existing code
    local reachable: array_2d.Array2D<boolean> = array_2d.new(full_map.w, full_map.h, false)

    full_map:foreachpoint(
        function (tile: Point, value: ShortestPathEntry)
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
function pathfinding.extend_path_to_point(path: {Point}, target: Point, max_length: integer, legal_tiles: Userdata): {Point}
    if legal_tiles:get(target.x, target.y) == 1 then
        return path
    end
    if path[#path] == target then
        return path
    end
    
    log.trace("Extend path")
    log.trace("Extend path", #path, target, max_length)

    local distance = function(tile: Point): integer
        return (legal_tiles:get(tile.x, tile.y) == 1) and 1 or 999
    end
    local extend_path = function(current_path: {Point}, t: Point, full_map: array_2d.Array2D<ShortestPathEntry>): {Point}
        local new_points = { t }
        log.trace("Extending path!", t)
        while (full_map:get_point(new_points[#new_points]).prev ~= current_path[#current_path]) do
            local prev = full_map:get_point(new_points[#new_points]).prev
            pt.add(new_points, prev)
        end
        -- TODO: config
        local visited = array_2d.new(16, 16, false)
        for _,p in ipairs(current_path) do
            visited:set_point(p, true)
        end
        while #new_points > 0 do
            local next_point = pt.pop(new_points)
            assert(next_point is Point)
            if visited:get_point(next_point) then
                while current_path[#current_path] ~= next_point do
                    pt.pop(current_path)
                end
            else
                visited:set_point(next_point, true)
                pt.add(current_path, next_point:copy())
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
                pt.add(out, path[j]:copy())
            end
            return out
        end
    end
    
    -- TODO: config
    local max_tile = point.of(16, 16)

    while #path > max_length + 1 do
        pt.pop(path)
    end
    while #path > 0 do
        local start = path[#path]
        local remaining_length = max_length + 1 - #path
        local full_map = _dijkstra_traversal(start.x, start.y, distance, remaining_length, max_tile)
        if full_map:get_point(target) ~= nil and full_map:get_point(target).cost <= remaining_length then
            return extend_path(path, target, full_map)
        end
        pt.pop(path)
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
