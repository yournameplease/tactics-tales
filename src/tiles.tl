require("src/util")

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

local TERRAIN_DATA = {
    [0] = {
        movement_cost = 1,
        dodge = 0
    },
    [1] = {
        movement_cost = 2,
        dodge = 0
    },
    [2] = {
        movement_cost = 2,
        dodge = 0
    },
    [3] = {
        movement_cost = 3,
        dodge = 0
    },
    [4] = {
        movement_cost = 4,
        dodge = 0
    },
    [5] = {
        movement_cost = 3,
        dodge = 0
    },
    [6] = {
        movement_cost = 5,
        dodge = 0
    },
    [7] = {
        movement_cost = 2,
        dodge = 0
    }
}

local TileManager = {}
TileManager.__index = TileManager

function TileManager.new(map_data, battle_state)
    self = setmetatable({}, TileManager)

    self.map_data = map_data
    self.battle_state = battle_state

    return self
end

function TileManager:get_terrain(x, y)
    local tile = mget(self.map_data.map_userdata[3], x,y)
    local flags = fget(tile)
    local terrain = (flags & 0xD) >> 1
    return TERRAIN_DATA[terrain]
end

-- cost to move onto x,y from any neighbor
function TileManager:movement_cost(x, y, side)
    local ground = self.map_data.map_userdata[3].bmp
    if x < 0 or y < 0 or x >= ground:width() or y >= ground:height() then
        return 999
    end

    local tile = ground:get(x,y)
    if tile == nil then return 999 end

    local unit = self.battle_state:get_unit_at_coordinates(x, y)
    if unit ~= nil then
        if unit.side ~= side then return 999 end
    end

    local flags = fget(tile)
    local solid = (flags & 0x1) == 0x1
    local terrain = (flags & 0xD) >> 1

    if solid then return 999 end
    return TERRAIN_DATA[terrain].movement_cost
end


-- Shared neighbor offsets (up, down, left, right)
local NEIGHBORS = { {x=0, y=1}, {x=0, y=-1}, {x=1, y=0}, {x=-1, y=0} }

-- --------------------------------------------------------------------------
-- Core Logic: Shared Dijkstra Engine
-- --------------------------------------------------------------------------
-- Returns a 2D map where map[x][y] = { cost = number, prev = {x, y} }
function TileManager:_dijkstra_traversal(start_x, start_y, side, max_cost)
    -- The output map containing cost and parent info for every visited node
    local visited_info = {}

    -- Helper to safely set data
    local function set_info(x, y, data)
        if not visited_info[x] then visited_info[x] = {} end
        visited_info[x][y] = data
    end

    -- Helper to safely get data
    local function get_info(x, y)
        if not visited_info[x] then return nil end
        return visited_info[x][y]
    end

    -- Initialize
    local priority_queue = {}

    -- Start node setup
    local start_cost = 0 -- Cost to be at the start is 0

    -- Sanity check: If the start tile itself is blocked or expensive
    -- (depending on your game logic, moving *off* start might cost 0 or terrain cost)
    if start_cost > max_cost then return {} end

    set_info(start_x, start_y, { cost = start_cost, prev = nil })
    add(priority_queue, {x = start_x, y = start_y, cost = start_cost})

    -- Main Loop
    while #priority_queue > 0 do
        -- 1. Pop the node with the lowest cost
        local min_node_cost = math.huge
        local min_index = -1

        for i, node in ipairs(priority_queue) do
            if node.cost < min_node_cost then
                min_node_cost = node.cost
                min_index = i
            end
        end

        local u = deli(priority_queue, min_index)
        local ux, uy, ucost = u.x, u.y, u.cost

        -- 2. Check if we found a better path to this node already
        -- (Standard Dijkstra laziness check)
        local current_info = get_info(ux, uy)
        if current_info and ucost <= current_info.cost then

            -- 3. Explore neighbors
            for _, offset in ipairs(NEIGHBORS) do
                local vx, vy = ux + offset.x, uy + offset.y

                -- Calculate cost to move FROM u INTO v
                local move_cost = self:movement_cost(vx, vy, side)

                -- Only proceed if the tile is traversable (movement_cost returns 999 for blocked)
                if move_cost < 999 then
                    local new_total = ucost + move_cost

                    -- 4. Check limits
                    if new_total <= max_cost then
                        local neighbor_info = get_info(vx, vy)

                        -- 5. Relaxation: Is this new path better than the old one?
                        if not neighbor_info or new_total < neighbor_info.cost then
                            -- Record the new cost and the tile we came from (ux, uy)
                            set_info(vx, vy, { cost = new_total, prev = {x=ux, y=uy} })
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

--- Calculates the cost and shortest path to ALL reachable tiles.
-- @return A table where map[x][y] = { cost = number, prev = {x, y} }
function TileManager:calculate_all_tile_costs(start_x, start_y, side, max_limit)
    local limit = max_limit or 99999
    return self:_dijkstra_traversal(start_x, start_y, side, limit)
end

-- @return list of { { x, y } } tile coordinates from start position
function TileManager:get_path_to_tile(all_tile_costs, x, y) -- could be static with current signature
    assert(all_tile_costs[x][y] ~= nil)
    local path = { { x = x, y = y} }
    while all_tile_costs[x][y].prev ~= nil do
        next_x = all_tile_costs[x][y].prev.x
        next_y = all_tile_costs[x][y].prev.y
        x, y = next_x, next_y
        add(path, { x = x, y = y })
    end
    return reverse_list(path)
end

--- Finds all tiles reachable from a starting point within a given total cost.
-- @return A table where reachable[x][y] = true (Compatible with original signature)
function TileManager:find_reachable_tiles(start_x, start_y, side, total_cost)
    -- 1. Get the detailed map from the core engine
    local full_map = self:_dijkstra_traversal(start_x, start_y, side, total_cost)

    -- 2. Transform it into the simple boolean map expected by existing code
    local reachable = {}

    for x, col in pairs(full_map) do
        reachable[x] = {}
        for y, info in pairs(col) do
            -- We don't need to check cost <= total_cost here because
            -- the core engine already filtered by total_cost.
            reachable[x][y] = true
        end
    end

    return reachable
end

return TileManager
