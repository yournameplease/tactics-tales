local type _ = require("busted")
local luassert <const> = require("luassert")

local lists = require("src.tactics.util.lists")

local record ValueWrapper
    value: integer
end

describe("tactics.util.lists", function()
    describe("size", function()
        it("should return the correct size of a list", function()
            luassert.are_equal(0, lists.size({}))
            luassert.are_equal(3, lists.size({1, 2, 3}))
        end)
    end)

    
    describe("add_all", function()
        it("should add all elements from one list to another", function()
            local list1 = {1, 2}
            local list2 = {3, 4}
            lists.add_all(list1, list2)
            luassert.are_same({1, 2, 3, 4}, list1)
        end)

        it("should handle empty lists correctly", function()
            local list1 = {1, 2}
            local list2 = {}
            lists.add_all(list1, list2)
            luassert.are_same({1, 2}, list1)

            local list3 = {}
            local list4 = {3, 4}
            lists.add_all(list3, list4)
            luassert.are_same({3, 4}, list3)
        end)
    end)

    describe("merge", function()
        it("should merge multiple lists into a new one", function()
            local list1 = {1, 2}
            local list2 = {3, 4}
            local list3 = {5}
            local merged = lists.merge(list1, list2, list3)
            luassert.are_same({1, 2, 3, 4, 5}, merged)
        end)

        it("should return a new list", function()
            local list1 = {1, 2}
            local list2 = {3, 4}
            local list3 = {5}
            local merged = lists.merge(list1, list2, list3)
            luassert.is_not_equal(merged, list1)
            luassert.is_not_equal(merged, list2)
            luassert.is_not_equal(merged, list3)
        end)

        it("should handle empty lists when merging", function()
            local list1 = {1}
            local list2 = {}
            local list3 = {2}
            local merged = lists.merge(list1, list2, list3)
            luassert.are_same({1, 2}, merged)
        end)
    end)

    describe("reverse and do_reverse", function()
        it("should reverse a list", function()
            local original = {1, 2, 3}
            local reversed = lists.reverse(original)
            luassert.are_same({3, 2, 1}, reversed)
            luassert.are_same({1, 2, 3}, original) -- Original should be unchanged

            local original2 = {1, 2, 3}
            local reversed2 = lists.do_reverse(original2)
            luassert.are_same({3, 2, 1}, reversed2)
            luassert.are_same({1, 2, 3}, original2) -- Original should be unchanged
        end)

        it("should handle empty lists", function()
            luassert.are_same({}, lists.reverse({}))
            luassert.are_same({}, lists.do_reverse({}))
        end)

        it("should handle single element lists", function()
            luassert.are_same({1}, lists.reverse({1}))
            luassert.are_same({1}, lists.do_reverse({1}))
        end)
    end)

    describe("filter and do_filter", function()
        it("should filter elements based on a predicate", function()
            local original = {1, 2, 3, 4, 5}
            local is_even = function(n: integer): boolean return n % 2 == 0 end
            local filtered = lists.filter(is_even)(original)
            luassert.are_same({2, 4}, filtered)
            luassert.are_same({1, 2, 3, 4, 5}, original) -- Original should be unchanged

            local filtered2 = lists.do_filter(original, is_even)
            luassert.are_same({2, 4}, filtered2)
            luassert.are_same({1, 2, 3, 4, 5}, original) -- Original should be unchanged
        end)

        it("should return an empty list if no elements match", function()
            local original = {1, 3, 5}
            local is_even = function(n: integer): boolean return n % 2 == 0 end
            luassert.are_same({}, lists.filter(is_even)(original))
            luassert.are_same({}, lists.do_filter(original, is_even))
        end)

        it("should handle empty input list", function()
            local is_even = function(n: integer): boolean return n % 2 == 0 end
            luassert.are_same({}, lists.filter(is_even)({}))
            luassert.are_same({}, lists.do_filter({}, is_even))
        end)
    end)

    describe("map and do_map", function()
        it("should transform each element based on a function", function()
            local original = {1, 2, 3}
            local double_fn = function(n: integer): integer return n * 2 end
            local doubled = lists.map(double_fn)(original)
            luassert.are_same({2, 4, 6}, doubled)
            luassert.are_same({1, 2, 3}, original) -- Original should be unchanged

            local doubled2 = lists.do_map(original, double_fn)
            luassert.are_same({2, 4, 6}, doubled2)
            luassert.are_same({1, 2, 3}, original) -- Original should be unchanged
        end)

        it("should handle empty input list", function()
            local double_fn = function(n: integer): integer return n * 2 end
            luassert.are_same({}, lists.map(double_fn)({}))
            luassert.are_same({}, lists.do_map({}, double_fn))
        end)
    end)

    describe("flat_map and do_flat_map", function()
        it("should transform each element to a list and flatten the result", function()
            local original = {1, 2}
            local duplicate_fn = function(n: integer): {integer} return {n, n} end
            local flattened = lists.flat_map(duplicate_fn)(original)
            luassert.are_same({1, 1, 2, 2}, flattened)
            luassert.are_same({1, 2}, original) -- Original should be unchanged

            local flattened2 = lists.do_flat_map(original, duplicate_fn)
            luassert.are_same({1, 1, 2, 2}, flattened2)
            luassert.are_same({1, 2}, original) -- Original should be unchanged
        end)

        it("should handle empty input list", function()
            local duplicate_fn = function(n: integer): {integer} return {n, n} end
            luassert.are_same({}, lists.flat_map(duplicate_fn)({}))
            luassert.are_same({}, lists.do_flat_map({}, duplicate_fn))
        end)
    end)

    describe("reduce and do_reduce", function()
        it("should reduce a list to a single value", function()
            local original = {1, 2, 3, 4}
            local sum_fn = function(acc: integer, n: integer): integer return acc + n end
            local sum_val = lists.reduce(0, sum_fn)(original)
            luassert.are_equal(10, sum_val)

            local sum_val2 = lists.do_reduce(original, 0, sum_fn)
            luassert.are_equal(10, sum_val2)
        end)

        it("should return the initial value for an empty list", function()
            local sum_fn = function(acc: integer, n: integer): integer return acc + n end
            luassert.are_equal(0, lists.reduce(0, sum_fn)({}))
            luassert.are_equal(0, lists.do_reduce({}, 0, sum_fn))
        end)
    end)

    describe("sum and do_sum", function()
        it("should sum elements of a list using a function", function()
            local original = {{value = 1}, {value = 2}, {value = 3}}
            local get_value = function(obj: ValueWrapper): integer return obj.value end
            local total = lists.sum(get_value)(original)
            luassert.are_equal(6, total)

            local total2 = lists.do_sum(original, get_value)
            luassert.are_equal(6, total2)
        end)

        it("should return 0 for an empty list", function()
            local get_value = function(obj: ValueWrapper): integer return obj.value end
            luassert.are_equal(0, lists.sum(get_value)({}))
            luassert.are_equal(0, lists.do_sum({}, get_value))
        end)
    end)

    describe("max", function()
        it("should find the maximum value based on a function", function()
            local original = {{value = 1}, {value = 5}, {value = 2}}
            local get_value = function(obj: ValueWrapper): integer return obj.value end
            local max_val = lists.max(get_value)(original)
            luassert.are_equal(5, max_val)
        end)

        it("should return 0 for an empty list", function()
            local get_value = function(obj: ValueWrapper): integer return obj.value end
            luassert.are_equal(0, lists.max(get_value)({}))
        end)
    end)

    describe("collect_map and do_collect_map", function()
        it("should convert a list of MapEntry to a map", function()
            local entries: {{string, integer}} = { {"a", 1}, {"b", 2} }
            -- local collected: {string: integer} = lists.collect_map()(entries)
            -- luassert.are_equal(1, collected["a"])
            -- luassert.are_equal(2, collected["b"])

            local collected2 = lists.do_collect_map(entries)
            luassert.are_equal(1, collected2["a"])
            luassert.are_equal(2, collected2["b"])
        end)

        it("should handle empty list", function()
            luassert.are_same({}, lists.collect_map()({}))
            luassert.are_same({}, lists.do_collect_map({}))
        end)
    end)

    describe("contains", function()
        it("should return true if the list contains the value", function()
            local list = {1, 2, 3}
            luassert.is_true(lists.contains(list, 2))
        end)

        it("should return false if the list does not contain the value", function()
            local list = {1, 2, 3}
            luassert.is_false(lists.contains(list, 4))
        end)

        it("should handle empty list", function()
            luassert.is_false(lists.contains({}, 1))
        end)
    end)
end)
