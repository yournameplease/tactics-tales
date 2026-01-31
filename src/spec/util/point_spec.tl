local type _ = require("busted")
local luassert <const> = require("luassert")
require("spec.picotron_shim")

local point = require("tactics.util.point")

describe("tactics.util.point", function()
    describe("metamethods", function()
        it("should correctly compare points with __eq", function()
            local p1 = point.of(10, 20)
            local p2 = point.of(10, 20)
            local p3 = point.of(20, 10)
            local p4 = point.of(10, 10)

            luassert.is_true(p1 == p2)
            luassert.is_false(p1 == p3)
            luassert.is_false(p1 == p4)
        end)

        it("should correctly add points with __add", function()
            local p1 = point.of(1, 2)
            local p2 = point.of(3, 4)
            local result = p1 + p2
            luassert.is_true(result == point.of(4, 6))
        end)

        it("should correctly subtract points with __sub", function()
            local p1 = point.of(5, 5)
            local p2 = point.of(1, 2)
            local result = p1 - p2
            luassert.is_true(result == point.of(4, 3))
        end)

        it("should correctly multiply points with __mul", function()
            -- point * point
            local p1 = point.of(2, 3)
            local p2 = point.of(4, 5)
            local result1 = p1 * p2
            luassert.is_true(result1 == point.of(8, 15))

            -- point * number
            local p3 = point.of(2, 3)
            local result2 = p3 * 3
            luassert.is_true(result2 == point.of(6, 9))
            
            -- number * point
            local p4 = point.of(2, 3)
            local result3 = 3 * p4
            luassert.is_true(result3 == point.of(6, 9))
            
            -- with floats
            local p5 = point.of(3, 5)
            local result4 = 2.5 * p5
            luassert.is_true(result4 == point.of(7, 12))
        end)

        it("should correctly negate points with __unm", function()
            local p = point.of(5, -10)
            local result = -p
            luassert.is_true(result == point.of(-5, 10))
        end)

        it("should correctly convert point to string with __tostring", function()
            local p = point.of(12, 34)
            luassert.are_equal("(12,34)", tostring(p))
        end)
    end)
    
    describe("copy", function()
        it("should create a new point with the same coordinates and be independent", function()
            local p1 = point.of(1, 2)
            local p2 = p1:copy()

            luassert.is_true(p1 == p2) -- Value equality

            -- Modify p1 and ensure p2 is unchanged
            p1.x = 99
            p1.y = 100

            luassert.is_true(p2.x == 1)
            luassert.is_true(p2.y == 2)
        end)
    end)
end)
