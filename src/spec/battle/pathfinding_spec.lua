local luassert = require("luassert")

local pathfinding = require("src.tactics.battle.pathfinding")
local point = require("src.tactics.util.point")

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

--- Build a minimal mock BattleMap backed by plain Lua tables.
--- get_terrain_fn(x, y) should return a TerrainData-shaped table or nil.
--- get_at_tile_fn(x, y) should return a unit-shaped table or nil (optional).
---@param w integer
---@param h integer
---@param get_terrain_fn fun(x: integer, y: integer): table|nil
---@param get_at_tile_fn? fun(x: integer, y: integer): table|nil
---@return table
local function make_mock_map(w, h, get_terrain_fn, get_at_tile_fn)
    local map = { width = w, height = h }
    function map:get_terrain(tile)
        return get_terrain_fn(tile.x, tile.y)
    end
    function map:get_at_tile(tile)
        if get_at_tile_fn then
            return get_at_tile_fn(tile.x, tile.y)
        end
        return nil
    end
    return map
end

--- Return a TerrainData table for open (passable, cost-1) terrain.
local function open_terrain()
    return { movement_cost = 1, solid = false, dodge = 0 }
end

--- Build a fully open WxH map where every tile has cost-1 terrain.
local function open_map(w, h)
    return make_mock_map(w, h, function() return open_terrain() end)
end

--- Build a mock legal_tiles object for extend_path_to_point tests.
--- legal_positions is a list of {x, y} pairs that are considered legal (value=1).
---@param legal_positions table[]
---@return userdata
local function make_legal_tiles(legal_positions)
    local function get(_, x, y)
        for _, p in ipairs(legal_positions) do
            if p[1] == x and p[2] == y then return 1 end
        end
        return 0
    end
    ---@diagnostic disable-next-line: return-type-mismatch
    return setmetatable({}, { __index = { get = get } })
end

-- ---------------------------------------------------------------------------
-- Tests
-- ---------------------------------------------------------------------------

describe("tactics.battle.pathfinding", function()

    -- -----------------------------------------------------------------------
    -- calculate_all_tile_costs
    -- -----------------------------------------------------------------------

    describe("calculate_all_tile_costs", function()

        it("should assign cost equal to taxicab distance on an open grid", function()
            local map = open_map(5, 5)
            local costs = pathfinding.calculate_all_tile_costs(map, 2, 2, "player", 99)

            -- Start tile has cost 0
            luassert.are_equal(0, costs:get(2, 2).cost)
            -- Orthogonal neighbours have cost 1
            luassert.are_equal(1, costs:get(3, 2).cost)
            luassert.are_equal(1, costs:get(1, 2).cost)
            luassert.are_equal(1, costs:get(2, 3).cost)
            luassert.are_equal(1, costs:get(2, 1).cost)
            -- Corner at taxicab distance 2
            luassert.are_equal(2, costs:get(4, 2).cost)
            luassert.are_equal(2, costs:get(0, 2).cost)
            -- All tiles on a 5x5 open grid are reachable from center
            for x = 0, 4 do
                for y = 0, 4 do
                    luassert.is_not_nil(costs:get(x, y))
                end
            end
        end)

        it("should not reach tiles beyond the max_limit", function()
            local map = open_map(5, 5)
            local costs = pathfinding.calculate_all_tile_costs(map, 2, 2, "player", 2)

            -- Within limit (taxicab ≤ 2)
            luassert.is_not_nil(costs:get(2, 2))
            luassert.is_not_nil(costs:get(3, 2))
            luassert.is_not_nil(costs:get(4, 2))
            -- Beyond limit (taxicab = 3)
            luassert.is_nil(costs:get(0, 0))
            luassert.is_nil(costs:get(4, 4))
        end)

        it("should not reach a solid tile", function()
            local map = make_mock_map(5, 5, function(x, y)
                if x == 2 and y == 1 then
                    return { movement_cost = 1, solid = true, dodge = 0 }
                end
                return open_terrain()
            end)
            local costs = pathfinding.calculate_all_tile_costs(map, 2, 2, "player", 99)

            luassert.is_nil(costs:get(2, 1))
        end)

        it("should not pass through a tile occupied by an enemy unit", function()
            local map = make_mock_map(5, 5,
                function() return open_terrain() end,
                function(x, y)
                    if x == 2 and y == 1 then
                        return { movement_side = "enemy" }
                    end
                    return nil
                end
            )
            local costs = pathfinding.calculate_all_tile_costs(map, 2, 2, "player", 99)

            -- The tile with the enemy unit is blocked
            luassert.is_nil(costs:get(2, 1))
        end)

        it("should pass through a tile occupied by a friendly unit", function()
            local map = make_mock_map(5, 5,
                function() return open_terrain() end,
                function(x, y)
                    if x == 2 and y == 1 then
                        return { movement_side = "player" }
                    end
                    return nil
                end
            )
            local costs = pathfinding.calculate_all_tile_costs(map, 2, 2, "player", 99)

            -- Friendly-occupied tile is still reachable
            luassert.is_not_nil(costs:get(2, 1))
        end)

    end)

    -- -----------------------------------------------------------------------
    -- get_path_to_tile
    -- -----------------------------------------------------------------------

    describe("get_path_to_tile", function()

        it("should return a straight path on an open grid", function()
            local map = open_map(5, 5)
            local costs = pathfinding.calculate_all_tile_costs(map, 0, 0, "player", 99)
            local target = point.of(2, 0)
            local path = pathfinding.get_path_to_tile(costs, target)

            -- Path length = taxicab distance + 1
            luassert.are_equal(3, #path)
            -- Starts at (0,0)
            luassert.are_equal(0, path[1].x)
            luassert.are_equal(0, path[1].y)
            -- Ends at target
            luassert.are_equal(2, path[#path].x)
            luassert.are_equal(0, path[#path].y)
        end)

        it("should reconstruct an L-shaped path with correct length", function()
            local map = open_map(5, 5)
            local costs = pathfinding.calculate_all_tile_costs(map, 0, 0, "player", 99)
            local target = point.of(1, 2)
            local path = pathfinding.get_path_to_tile(costs, target)

            -- Taxicab distance = 3, so path has 4 points
            luassert.are_equal(4, #path)
            -- Starts at (0,0) and ends at target
            luassert.are_equal(0, path[1].x)
            luassert.are_equal(0, path[1].y)
            luassert.are_equal(1, path[#path].x)
            luassert.are_equal(2, path[#path].y)
            -- Each step differs by exactly 1 in one axis
            for i = 2, #path do
                local dx = math.abs(path[i].x - path[i-1].x)
                local dy = math.abs(path[i].y - path[i-1].y)
                luassert.are_equal(1, dx + dy)
            end
        end)

        it("should return a single-element path when tile equals start", function()
            local map = open_map(5, 5)
            local costs = pathfinding.calculate_all_tile_costs(map, 2, 2, "player", 99)
            local path = pathfinding.get_path_to_tile(costs, point.of(2, 2))

            luassert.are_equal(1, #path)
            luassert.are_equal(2, path[1].x)
            luassert.are_equal(2, path[1].y)
        end)

    end)

    -- -----------------------------------------------------------------------
    -- find_reachable_tiles
    -- -----------------------------------------------------------------------

    describe("find_reachable_tiles", function()

        it("should mark all tiles within cost as reachable", function()
            local map = open_map(5, 5)
            local reachable = pathfinding.find_reachable_tiles(map, 0, 0, "player", 2)

            -- Within budget
            luassert.is_true(reachable:get(0, 0))
            luassert.is_true(reachable:get(1, 0))
            luassert.is_true(reachable:get(0, 1))
            luassert.is_true(reachable:get(2, 0))
            luassert.is_true(reachable:get(0, 2))
            luassert.is_true(reachable:get(1, 1))
        end)

        it("should include tiles at exactly the cost limit", function()
            local map = open_map(5, 5)
            local reachable = pathfinding.find_reachable_tiles(map, 0, 0, "player", 2)

            -- Taxicab distance 2 = exactly at limit → should be true
            luassert.is_true(reachable:get(2, 0))
            luassert.is_true(reachable:get(0, 2))
        end)

        it("should not include tiles beyond the cost limit", function()
            local map = open_map(5, 5)
            local reachable = pathfinding.find_reachable_tiles(map, 0, 0, "player", 2)

            -- Taxicab distance 3 = beyond limit → should be nil or false
            luassert.is_falsy(reachable:get(3, 0))
            luassert.is_falsy(reachable:get(0, 3))
        end)

        it("should not mark solid tiles as reachable", function()
            local map = make_mock_map(5, 5, function(x, y)
                if x == 1 and y == 0 then
                    return { movement_cost = 1, solid = true, dodge = 0 }
                end
                return open_terrain()
            end)
            local reachable = pathfinding.find_reachable_tiles(map, 0, 0, "player", 3)

            luassert.is_falsy(reachable:get(1, 0))
        end)

    end)

    -- -----------------------------------------------------------------------
    -- extend_path_to_point
    -- -----------------------------------------------------------------------

    describe("extend_path_to_point", function()

        it("should return the original path unchanged when target is not legal", function()
            local path = { point.of(0, 0), point.of(1, 0) }
            local target = point.of(5, 5)
            -- legal_tiles has no legal positions → target returns 0
            local legal = make_legal_tiles({})
            local result = pathfinding.extend_path_to_point(path, target, 10, legal)

            luassert.are_equal(2, #result)
            luassert.are_equal(0, result[1].x)
            luassert.are_equal(0, result[1].y)
            luassert.are_equal(1, result[2].x)
            luassert.are_equal(0, result[2].y)
        end)

        it("should trim the path to the target when it already appears in the path", function()
            local path = { point.of(0, 0), point.of(1, 0), point.of(2, 0) }
            local target = point.of(1, 0)
            -- All tiles on the path are legal
            local legal = make_legal_tiles({{0,0},{1,0},{2,0}})
            local result = pathfinding.extend_path_to_point(path, target, 10, legal)

            luassert.are_equal(2, #result)
            luassert.are_equal(0, result[1].x)
            luassert.are_equal(0, result[1].y)
            luassert.are_equal(1, result[2].x)
            luassert.are_equal(0, result[2].y)
        end)

        it("should extend the path towards a new reachable target", function()
            -- Start at (0,0), legal strip along x-axis up to x=3
            local legal = make_legal_tiles({{0,0},{1,0},{2,0},{3,0}})
            local path = { point.of(0, 0) }
            local target = point.of(3, 0)
            local result = pathfinding.extend_path_to_point(path, target, 4, legal)

            -- Path should end at target
            luassert.are_equal(3, result[#result].x)
            luassert.are_equal(0, result[#result].y)
            -- Length should not exceed max_length + 1
            luassert.is_true(#result <= 5)
        end)

        it("should trim and then extend when the path is longer than max_length", function()
            -- Path going down: 5 elements (longer than max_length=2 + 1 = 3)
            local path = {
                point.of(0, 0), point.of(0, 1), point.of(0, 2),
                point.of(0, 3), point.of(0, 4),
            }
            -- Target is (1,0), reachable via (0,0) and (1,0)
            local legal = make_legal_tiles({{0,0},{0,1},{0,2},{0,3},{0,4},{1,0},{1,1}})
            local target = point.of(1, 0)
            local result = pathfinding.extend_path_to_point(path, target, 2, legal)

            -- Result should end at target
            luassert.are_equal(1, result[#result].x)
            luassert.are_equal(0, result[#result].y)
            -- Result length must not exceed max_length + 1
            luassert.is_true(#result <= 3)
        end)

    end)

end)
