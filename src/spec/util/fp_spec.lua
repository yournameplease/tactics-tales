local luassert = require("luassert")

local fp = require("src.tactics.util.fp")

describe("tactics.util.fp", function()
    describe("fn_and", function()
        it("should return true if all functions return true", function()
            local f1 = function(n) return n > 0 end
            local f2 = function(n) return n < 10 end
            local combined = fp.fn_and(f1, f2)
            luassert.is_true(combined(5))
        end)

        it("should return false if any function returns false", function()
            local f1 = function(n) return n > 0 end
            local f2 = function(n) return n < 10 end
            local combined = fp.fn_and(f1, f2)
            luassert.is_false(combined(11))
        end)

        it("should work with a single function", function()
            local f1 = function(s) return s == "hello" end
            local combined = fp.fn_and(f1)
            luassert.is_true(combined("hello"))
            luassert.is_false(combined("world"))
        end)
    end)

    describe("fn_true", function()
        it("should always return true", function()
            luassert.is_true(fp.fn_true())
        end)
    end)

    describe("not_nil", function()
        it("should return true for non-nil values", function()
            luassert.is_true(fp.not_nil(0))
            luassert.is_true(fp.not_nil(""))
            luassert.is_true(fp.not_nil({}))
        end)

        it("should return false for nil", function()
            luassert.is_false(fp.not_nil(nil))
        end)
    end)

    describe("pipeline", function()
        it("pipeline_1 should apply a single function", function()
            local add_one = function(n) return n + 1 end
            local pipeline = fp.pipeline_1(add_one)
            luassert.are_equal(2, pipeline(1))
        end)

        it("pipeline_2 should apply two functions in order", function()
            local add_one = function(n) return n + 1 end
            local multiply_by_two = function(n) return n * 2 end
            local pipeline = fp.pipeline_2(add_one, multiply_by_two)
            -- (1 + 1) * 2 = 4
            luassert.are_equal(4, pipeline(1))
        end)

        it("pipeline_3 should apply three functions in order", function()
            local add_one = function(n) return n + 1 end
            local multiply_by_two = function(n) return n * 2 end
            local to_string = function(n) return "Result: " .. tostring(n) end
            local pipeline = fp.pipeline_3(add_one, multiply_by_two, to_string)
            luassert.are_equal("Result: 4", pipeline(1))
        end)

        it("pipeline_4 should apply four functions in order", function()
            local fn1 = function(n) return n + 1 end
            local fn2 = function(n) return n * 2 end
            local fn3 = function(n) return n - 3 end
            local fn4 = function(n) return n * 10 end
            local pipeline = fp.pipeline_4(fn1, fn2, fn3, fn4)
            -- (((1 + 1) * 2) - 3) * 10 = 10
            luassert.are_equal(10, pipeline(1))
        end)

        it("pipeline_5 should apply five functions in order", function()
            local fn1 = function(s) return s .. "b" end
            local fn2 = function(s) return s .. "c" end
            local fn3 = function(s) return s .. "d" end
            local fn4 = function(s) return s .. "e" end
            local fn5 = function(s) return s .. "f" end
            local pipeline = fp.pipeline_5(fn1, fn2, fn3, fn4, fn5)
            luassert.are_equal("abcdef", pipeline("a"))
        end)
    end)
end)
