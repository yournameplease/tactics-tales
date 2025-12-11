require("src/types")

require("src/util")
require("src/battle/battle_map")
require("src/battle/map/map_manager")
require("src/systems/service")

-- tile flags:
-- 0: empty/solid
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
local function movement_cost(battle_map: BattleMap, tile: TilePoint, side: Side): integer
    local terrain = battle_map:get_terrain(tile)
    if terrain == nil then return 999 end

    local unit = battle_map:get_at_tile(tile)
    if unit ~= nil then
        if unit.side ~= side then return 999 end
    end

    if terrain.solid then return 999 end
    return terrain.movement_cost
end


-- Shared neighbor offsets (up, down, left, right)
local NEIGHBORS = { {x=0, y=1}, {x=0, y=-1}, {x=1, y=0}, {x=-1, y=0} }

global record ShortestPathEntry
    cost: integer
    prev: TilePoint
end

-- --------------------------------------------------------------------------
-- Core Logic: Shared Dijkstra Engine
-- --------------------------------------------------------------------------
-- Returns a 2D map where map[x][y] = { cost = number, prev = {x, y} }
local function _dijkstra_traversal(battle_map: BattleMap, start_x: integer, start_y: integer, side: Side, max_cost: integer): Array2D<ShortestPathEntry>
    -- The output map containing cost and parent info for every visited node
    local visited_info: Array2D<ShortestPathEntry> = Array2D.new(battle_map.width, battle_map.height)

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
    add(priority_queue, {x = start_x, y = start_y, cost = start_cost})

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

        local u = deli(priority_queue, min_index)
        assert(u is ShortestPathQueueEntry)
        local ux, uy, ucost = u.x, u.y, u.cost

        LOG.trace("Processing shortest path point", ux, uy, ucost)
        -- 2. Check if we found a better path to this node already
        -- (Standard Dijkstra laziness check)
        local current_info = visited_info:get(ux, uy)
        if current_info and ucost <= current_info.cost then

            -- 3. Explore neighbors
            for _, offset in ipairs(NEIGHBORS) do
                local vx, vy = ux + offset.x, uy + offset.y

                -- Calculate cost to move FROM u INTO v
                local move_cost = movement_cost(battle_map, { x=vx, y=vy }, side)
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
                            visited_info:set(vx, vy, { cost = new_total, prev = TilePoint.of(ux, uy) })
                            add(priority_queue, {x = vx, y = vy, cost = new_total})
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

local record Pathfinding
end

--- Calculates the cost and shortest path to ALL reachable tiles.
-- @return A table where map[x][y] = { cost = number, prev = {x, y} }
function Pathfinding.calculate_all_tile_costs(battle_map: BattleMap, start_x: integer, start_y: integer, side: Side, max_limit: integer): Array2D<ShortestPathEntry>
    local limit = max_limit or 99999
    return _dijkstra_traversal(battle_map, start_x, start_y, side, limit)
end 

-- @return list of { { x, y } } tile coordinates from start position
function Pathfinding.get_path_to_tile(all_tile_costs: Array2D<ShortestPathEntry>, tile: TilePoint): { TilePoint } -- could be static with current signature
    assert(all_tile_costs:get_point(tile) ~= nil)
    local path: {TilePoint} = {}
    add(path, tile:copy())
    local next_tile = tile
    while all_tile_costs:get_point(next_tile).prev ~= nil do
        next_tile = all_tile_costs:get_point(next_tile).prev
        add(path, next_tile:copy())
    end
    return reverse_list(path)
end

--- Finds all tiles reachable from a starting point within a given total cost.
-- @return A table where reachable[x][y] = true (Compatible with original signature)
function Pathfinding.find_reachable_tiles(battle_map: BattleMap, start_x: integer, start_y: integer, side: Side, total_cost: integer): Array2D<boolean>
    -- 1. Get the detailed map from the core engine
    local full_map = _dijkstra_traversal(battle_map, start_x, start_y, side, total_cost)

    -- 2. Transform it into the simple boolean map expected by existing code
    local reachable: Array2D<boolean> = Array2D.new(full_map.w, full_map.h, false)

    full_map:foreachpoint(
        function (tile: TilePoint, value: ShortestPathEntry)
            -- We don't need to check cost <= total_cost here because
            -- the core engine already filtered by total_cost.
            -- TODO: not positive after refactor to Array2D.  investigate.
            if (value.cost <= total_cost) then
                reachable:set_point(tile, true)
            end
        end
    )

    return reachable
end

return Pathfinding
