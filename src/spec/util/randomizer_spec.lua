local luassert = require("luassert")

local randomizer = require("src.tactics.util.randomizer")

-- Helper: replace rnd with a function that returns each value in sequence.
-- rndi(n) = floor(rnd(n)), so passing an integer k makes rndi return k.
local original_rnd = _G.rnd

local function rnd_returns(...)
    local vals = { ... }
    local idx = 0
    return function(_limit)
        idx = idx + 1
        return vals[idx]
    end
end

after_each(function()
    _G.rnd = original_rnd
end)

describe("tactics.util.randomizer", function()
    describe("weighted_option_selector.of (uniform weights)", function()
        -- of() uses the fast path: all weights are 1, so rndi(n)+1 is the direct index.

        it("should pick the first option when rnd returns 0", function()
            _G.rnd = rnd_returns(0)
            local sel = randomizer.weighted_option_selector.of("a", "b", "c")
            luassert.are_equal("a", sel:pick_random())
        end)

        it("should pick the second option when rnd returns 1", function()
            _G.rnd = rnd_returns(1)
            local sel = randomizer.weighted_option_selector.of("a", "b", "c")
            luassert.are_equal("b", sel:pick_random())
        end)

        it("should pick the last option when rnd returns n-1", function()
            _G.rnd = rnd_returns(2)
            local sel = randomizer.weighted_option_selector.of("a", "b", "c")
            luassert.are_equal("c", sel:pick_random())
        end)
    end)

    describe("weighted_option_selector.of_weighted (explicit weights)", function()
        -- options: {"a",1}, {"b",2}, {"c",1} — total_weight=4
        -- rndi(4)+1 = i; then walk: subtract each weight until i <= 0.
        --   i=1: 1-1=0 <= 0 → "a"
        --   i=2: 2-1=1 > 0; 1-2=-1 <= 0 → "b"
        --   i=3: 3-1=2 > 0; 2-2=0 <= 0 → "b"
        --   i=4: 4-1=3 > 0; 3-2=1 > 0; 1-1=0 <= 0 → "c"

        it("should pick 'a' (weight 1) when rnd returns 0", function()
            _G.rnd = rnd_returns(0)
            local sel = randomizer.weighted_option_selector.of_weighted({ "a", 1 }, { "b", 2 }, { "c", 1 })
            luassert.are_equal("a", sel:pick_random())
        end)

        it("should pick 'b' (weight 2) when rnd returns 1", function()
            _G.rnd = rnd_returns(1)
            local sel = randomizer.weighted_option_selector.of_weighted({ "a", 1 }, { "b", 2 }, { "c", 1 })
            luassert.are_equal("b", sel:pick_random())
        end)

        it("should still pick 'b' when rnd returns 2 (within b's weight range)", function()
            _G.rnd = rnd_returns(2)
            local sel = randomizer.weighted_option_selector.of_weighted({ "a", 1 }, { "b", 2 }, { "c", 1 })
            luassert.are_equal("b", sel:pick_random())
        end)

        it("should pick 'c' (weight 1) when rnd returns 3", function()
            _G.rnd = rnd_returns(3)
            local sel = randomizer.weighted_option_selector.of_weighted({ "a", 1 }, { "b", 2 }, { "c", 1 })
            luassert.are_equal("c", sel:pick_random())
        end)
    end)

    describe("weighted_option_selector.of_recursive", function()
        -- Two sub-selectors: first has {"a",1},{"b",1} weighted by 2; second has {"c",1},{"d",1} weighted by 1.
        -- Flattened options: {"a",2},{"b",2},{"c",1},{"d",1} — total_weight=6.
        --   i=1: 1-2=-1 <= 0 → "a"
        --   i=3: 3-2=1 > 0; 1-2=-1 <= 0 → "b"
        --   i=5: 5-2=3>0; 3-2=1>0; 1-1=0<=0 → "c"
        --   i=6: 6-2=4>0; 4-2=2>0; 2-1=1>0; 1-1=0<=0 → "d"

        local function make_sub(a, b)
            return randomizer.weighted_option_selector.of_weighted({ a, 1 }, { b, 1 })
        end

        it("should pick from the heavier sub-selector when rnd is low", function()
            _G.rnd = rnd_returns(0) -- i=1
            local sel = randomizer.weighted_option_selector.of_recursive(
                { make_sub("a", "b"), 2 },
                { make_sub("c", "d"), 1 }
            )
            luassert.are_equal("a", sel:pick_random())
        end)

        it("should pick the second option of the heavier sub-selector", function()
            _G.rnd = rnd_returns(2) -- i=3
            local sel = randomizer.weighted_option_selector.of_recursive(
                { make_sub("a", "b"), 2 },
                { make_sub("c", "d"), 1 }
            )
            luassert.are_equal("b", sel:pick_random())
        end)

        it("should pick from the lighter sub-selector when rnd is higher", function()
            _G.rnd = rnd_returns(4) -- i=5
            local sel = randomizer.weighted_option_selector.of_recursive(
                { make_sub("a", "b"), 2 },
                { make_sub("c", "d"), 1 }
            )
            luassert.are_equal("c", sel:pick_random())
        end)
    end)

    describe("random_range", function()
        describe("between", function()
            it("should return min_value when rnd returns 0", function()
                _G.rnd = rnd_returns(0)
                local r = randomizer.random_range.between(5, 10)
                luassert.are_equal(5, r:pick_random())
            end)

            it("should return max_value when rnd returns the range size", function()
                _G.rnd = rnd_returns(5) -- rndi(6)=5; 5+5=10
                local r = randomizer.random_range.between(5, 10)
                luassert.are_equal(10, r:pick_random())
            end)

            it("should return a mid-range value", function()
                _G.rnd = rnd_returns(3) -- rndi(6)=3; 5+3=8
                local r = randomizer.random_range.between(5, 10)
                luassert.are_equal(8, r:pick_random())
            end)
        end)

        describe("of", function()
            it("should return 0 when rnd returns 0", function()
                _G.rnd = rnd_returns(0)
                local r = randomizer.random_range.of(4) -- between(0, 3)
                luassert.are_equal(0, r:pick_random())
            end)

            it("should return n-1 when rnd returns n-1", function()
                _G.rnd = rnd_returns(3) -- rndi(4)=3; 0+3=3
                local r = randomizer.random_range.of(4)
                luassert.are_equal(3, r:pick_random())
            end)
        end)
    end)

    describe("list_selector", function()
        it("should collect pick_random results from each sub-randomizer", function()
            -- Use two fixed ranges that each always return the same value.
            _G.rnd = rnd_returns(0, 0)
            local r1 = randomizer.random_range.between(7, 7)
            local r2 = randomizer.random_range.between(42, 42)
            local sel = randomizer.list_selector.of_randomizers(r1, r2)
            luassert.are_same({ 7, 42 }, sel:pick_random())
        end)

        it("should return results in sub-randomizer order", function()
            _G.rnd = rnd_returns(0, 1, 2)
            local sel = randomizer.list_selector.of_randomizers(
                randomizer.weighted_option_selector.of("a", "b", "c"),
                randomizer.weighted_option_selector.of("x", "y", "z"),
                randomizer.weighted_option_selector.of("p", "q", "r")
            )
            luassert.are_same({ "a", "y", "r" }, sel:pick_random())
        end)
    end)
end)
