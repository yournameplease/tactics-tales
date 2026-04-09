local luassert = require("luassert")

local random = require("src.tactics.util.random")

-- Helper: replace pt.rnd with a function that returns each value in sequence.
-- rndi(n) = floor(rnd(n)), so passing an integer k makes rndi return k.
local original_rnd = pt.rnd

local function rnd_returns(...)
    local vals = {...}
    local idx = 0
    return function(_limit)
        idx = idx + 1
        return vals[idx]
    end
end

after_each(function()
    pt.rnd = original_rnd
end)

describe("tactics.util.random", function()
    describe("rndi", function()
        it("should return 0 when rnd returns 0", function()
            pt.rnd = rnd_returns(0)
            luassert.are_equal(0, random.rndi(5))
        end)

        it("should return the floor of rnd's return value", function()
            pt.rnd = rnd_returns(3)
            luassert.are_equal(3, random.rndi(5))
        end)
    end)

    describe("choose_random_from_list", function()
        it("should return the first element when rnd returns 0", function()
            pt.rnd = rnd_returns(0)
            local result = random.choose_random_from_list({"a", "b", "c"})
            luassert.are_equal("a", result)
        end)

        it("should return the last element when rnd returns the last index", function()
            pt.rnd = rnd_returns(2)
            local result = random.choose_random_from_list({"a", "b", "c"})
            luassert.are_equal("c", result)
        end)

        it("should return the middle element when rnd returns the middle index", function()
            pt.rnd = rnd_returns(1)
            local result = random.choose_random_from_list({"a", "b", "c"})
            luassert.are_equal("b", result)
        end)

        it("should work for a single-element list", function()
            pt.rnd = rnd_returns(0)
            local result = random.choose_random_from_list({"only"})
            luassert.are_equal("only", result)
        end)
    end)

    describe("choose_random_from_table", function()
        it("should return the sole value when the table has one entry", function()
            pt.rnd = rnd_returns(0)
            local result = random.choose_random_from_table({ key = "value" })
            luassert.are_equal("value", result)
        end)
    end)
end)
