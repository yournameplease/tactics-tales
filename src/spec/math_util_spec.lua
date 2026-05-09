local luassert = require("luassert")

local math_util = require("src.tactics.math_util")

describe("tactics.math_util", function()
    describe("smoothstep", function()
        it("returns 0 at t=0", function()
            luassert.are_equal(0, math_util.smoothstep(0))
        end)

        it("returns 1 at t=1", function()
            luassert.are_equal(1, math_util.smoothstep(1))
        end)

        it("returns 0.5 at t=0.5", function()
            luassert.are_equal(0.5, math_util.smoothstep(0.5))
        end)

        it("clamps below 0 to 0", function()
            luassert.are_equal(0, math_util.smoothstep(-1))
        end)

        it("clamps above 1 to 1", function()
            luassert.are_equal(1, math_util.smoothstep(2))
        end)

        it("is monotonically increasing between 0 and 1", function()
            local prev = math_util.smoothstep(0)
            for i = 1, 20 do
                local t = i / 20
                local curr = math_util.smoothstep(t)
                luassert.is_true(curr >= prev)
                prev = curr
            end
        end)
    end)
end)
