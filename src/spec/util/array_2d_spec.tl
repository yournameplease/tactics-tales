local type _ = require("busted")
local luassert <const> = require("luassert")

local array_2d = require("src.tactics.util.array_2d")
local point = require("src.tactics.util.point")

describe("tactics.util.array_2d", function()
    local width = 5
    local height = 3

    describe("new", function()
        it("should create a new Array2D with specified dimensions", function()
            local arr = array_2d.new(width, height)
            luassert.are_equal(width, arr.w)
            luassert.are_equal(height, arr.h)
            luassert.is_nil(arr:get(0, 0))
        end)

        it("should initialize all elements with a default value if provided", function()
            local default_val = "empty"
            local arr = array_2d.new(width, height, default_val)
            for x = 0, width - 1 do
                for y = 0, height - 1 do
                    luassert.are_equal(default_val, arr:get(x, y))
                end
            end
        end)
    end)

    
    describe("is_in_range and is_point_in_range", function()
        local arr = array_2d.new(width, height)

        it("should return true for coordinates within bounds", function()
            luassert.is_true(arr:is_in_range(0, 0))
            luassert.is_true(arr:is_in_range(width - 1, height - 1))
            luassert.is_true(arr:is_point_in_range(point.of(0, 0)))
            luassert.is_true(arr:is_point_in_range(point.of(width - 1, height - 1)))
        end)

        it("should return false for coordinates out of bounds (negative)", function()
            luassert.is_false(arr:is_in_range(-1, 0))
            luassert.is_false(arr:is_in_range(0, -1))
            luassert.is_false(arr:is_point_in_range(point.of(-1, 0)))
            luassert.is_false(arr:is_point_in_range(point.of(0, -1)))
        end)

        it("should return false for coordinates out of bounds (positive)", function()
            luassert.is_false(arr:is_in_range(width, 0))
            luassert.is_false(arr:is_in_range(0, height))
            luassert.is_false(arr:is_point_in_range(point.of(width, 0)))
            luassert.is_false(arr:is_point_in_range(point.of(0, height)))
        end)
    end)

    
    describe("get, get_point, set, set_point", function()
        local arr: array_2d.Array2D<string|nil> = array_2d.new(width, height)

        it("should correctly set and get values by coordinates", function()
            arr:set(1, 1, "test_value_1_1")
            luassert.are_equal("test_value_1_1", arr:get(1, 1))

            arr:set(width - 1, height - 1, "test_value_max")
            luassert.are_equal("test_value_max", arr:get(width - 1, height - 1))
        end)

        it("should assert on out of bounds access for set/get", function()
            luassert.error_matches(function() arr:set(-1, 0, "invalid") end, "assertion failed!")
            luassert.error_matches(function() arr:get(width, 0) end, "assertion failed!")
        end)
    end)

    
    describe("foreach", function()
        it("should iterate over all elements and call the callback with correct coordinates and values", function()
            local arr = array_2d.new(2, 2, 0)
            arr:set(0, 0, 1)
            arr:set(1, 0, 2)
            arr:set(0, 1, 3)
            arr:set(1, 1, 4)

            local visited = {}
            arr:foreach(function(x, y, v)
                visited[tostring(x) .. "," .. tostring(y)] = v
            end)

            local count = 0
            for _,_ in pairs(visited) do
                count = count + 1
            end
            luassert.are_equal(4, count)
        end)
    end)

    
    describe("foreachpoint", function()
        it("should iterate over all elements and call the callback with correct point and values", function()
            local arr = array_2d.new(2, 2, 0)
            arr:set(0, 0, 10)
            arr:set(1, 0, 20)

            local visited_points = {}
            arr:foreachpoint(function(p: point.Point, v)
                visited_points[tostring(p.x) .. "," .. tostring(p.y)] = v
            end)

            luassert.are_equal(10, visited_points["0,0"])
            luassert.are_equal(20, visited_points["1,0"])
            luassert.are_equal(0, visited_points["0,1"]) -- Default value
        end)
    end)

    
    describe("map", function()
        it("should create a new Array2D with transformed values", function()
            local arr = array_2d.new(2, 2, 1)
            arr:set(0, 0, 10)
            arr:set(1, 1, 20)

            local transform_fn_1 = function(v: number): number
                return v * 2
            end
            local mapped_arr = arr:map(transform_fn_1)

            luassert.are_equal(arr.w, mapped_arr.w)
            luassert.are_equal(arr.h, mapped_arr.h)
            luassert.are_equal(20, mapped_arr:get(0, 0))
            luassert.are_equal(2, mapped_arr:get(1, 0))
            luassert.are_equal(2, mapped_arr:get(0, 1))
            luassert.are_equal(40, mapped_arr:get(1, 1))
        end)

        it("should create a new Array2D with different types if transformation changes type", function()
            local arr = array_2d.new(1, 1, 5)
            local transform_fn_2 = function(v: number): string
                return "value_" .. tostring(v)
            end
            local mapped_arr = arr:map(transform_fn_2)
            luassert.are_equal("value_5", mapped_arr:get(0, 0))
        end)
    end)
    
end)
