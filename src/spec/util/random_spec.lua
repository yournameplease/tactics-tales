local luassert = require("luassert")

local random = require("src.tactics.util.random")

-- Helper: replace rnd with a function that returns each value in sequence.
-- rndi(n) = floor(rnd(n)), so passing an integer k makes rndi return k.
local original_rnd = _G.rnd

local function rnd_returns(...)
    local vals = {...}
    local idx = 0
    return function(_limit)
        idx = idx + 1
        return vals[idx]
    end
end

after_each(function()
    _G.rnd = original_rnd
end)

describe("tactics.util.random", function()
    describe("rndi", function()
        it("should return 0 when rnd returns 0", function()
            _G.rnd = rnd_returns(0)
            luassert.are_equal(0, random.rndi(5))
        end)

        it("should return the floor of rnd's return value", function()
            _G.rnd = rnd_returns(3)
            luassert.are_equal(3, random.rndi(5))
        end)
    end)

    describe("choose_random_from_list", function()
        it("should return the first element when rnd returns 0", function()
            _G.rnd = rnd_returns(0)
            local result = random.choose_random_from_list({"a", "b", "c"})
            luassert.are_equal("a", result)
        end)

        it("should return the last element when rnd returns the last index", function()
            _G.rnd = rnd_returns(2)
            local result = random.choose_random_from_list({"a", "b", "c"})
            luassert.are_equal("c", result)
        end)

        it("should return the middle element when rnd returns the middle index", function()
            _G.rnd = rnd_returns(1)
            local result = random.choose_random_from_list({"a", "b", "c"})
            luassert.are_equal("b", result)
        end)

        it("should work for a single-element list", function()
            _G.rnd = rnd_returns(0)
            local result = random.choose_random_from_list({"only"})
            luassert.are_equal("only", result)
        end)
    end)

    describe("choose_random_from_table", function()
        it("should return the sole value when the table has one entry", function()
            _G.rnd = rnd_returns(0)
            local result = random.choose_random_from_table({ key = "value" })
            luassert.are_equal("value", result)
        end)
    end)
end)

describe("random.new", function()
    describe("rndi", function()
        it("should return a value in [0, i-1]", function()
            local rng = random.new(12345)
            for _ = 1, 20 do
                local v = rng:rndi(10)
                luassert.is_true(v >= 0 and v < 10)
            end
        end)

        it("should produce the same sequence for the same seed", function()
            local a = random.new(99999)
            local b = random.new(99999)
            for _ = 1, 10 do
                luassert.are_equal(a:rndi(100), b:rndi(100))
            end
        end)

        it("should produce different sequences for different seeds", function()
            local a = random.new(1)
            local b = random.new(2)
            local same = true
            for _ = 1, 10 do
                if a:rndi(1000) ~= b:rndi(1000) then same = false end
            end
            luassert.is_false(same)
        end)
    end)

    describe("choose_random_from_list", function()
        it("should always return the only element for a single-element list", function()
            local rng = random.new(42)
            luassert.are_equal("only", rng:choose_random_from_list({"only"}))
        end)

        it("should return elements from the list", function()
            local rng = random.new(7)
            local options = {"a", "b", "c"}
            for _ = 1, 20 do
                local v = rng:choose_random_from_list(options)
                luassert.is_true(v == "a" or v == "b" or v == "c")
            end
        end)
    end)

    describe("choose_random_from_table", function()
        it("should return the sole value when the table has one entry", function()
            local rng = random.new(1)
            luassert.are_equal("value", rng:choose_random_from_table({ key = "value" }))
        end)
    end)

    describe("get_state / set_state", function()
        it("should restore sequence after set_state", function()
            local rng = random.new(54321)
            -- Advance a few steps and capture state.
            for _ = 1, 5 do rng:rndi(100) end
            local state = rng:get_state()
            local v1 = rng:rndi(1000)
            local v2 = rng:rndi(1000)
            -- Restore and re-run — must match.
            rng:set_state(state)
            luassert.are_equal(v1, rng:rndi(1000))
            luassert.are_equal(v2, rng:rndi(1000))
        end)
    end)

    describe("seed edge cases", function()
        it("should replace a seed of 0 with 1 and still produce output", function()
            local rng = random.new(0)
            luassert.is_true(rng:rndi(10) >= 0)
        end)

        it("should accept a float seed by flooring it", function()
            local rng_float = random.new(42.9)
            local rng_int   = random.new(42)
            luassert.are_equal(rng_int:rndi(1000), rng_float:rndi(1000))
        end)
    end)
end)
