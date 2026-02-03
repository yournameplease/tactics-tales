local type _ = require("busted")
local luassert <const> = require("luassert")

local maps = require("src.tactics.util.maps")

describe("tactics.util.maps", function()
    describe("set", function()
        it("should create a set from a list of values", function()
            local values = {"a", "b", "c"}
            local s = maps.set(values)
            luassert.is_true(s["a"])
            luassert.is_true(s["b"])
            luassert.is_true(s["c"])
            luassert.is_nil(s["d"])
        end)

        it("should handle an empty list", function()
            local s = maps.set({})
            luassert.are_same({}, s)
        end)
    end)

    describe("map and do_map", function()
        it("should transform map values", function()
            local m = {a = 1, b = 2}
            local transform = function(_k: string, v: integer): integer return v * 2 end
            local mapped = maps.do_map(m, transform)
            luassert.are_same({a = 2, b = 4}, mapped)

            local mapped2 = maps.map(transform)(m)
            luassert.are_same({a = 2, b = 4}, mapped2)
        end)
    end)

    describe("full_map", function()
        it("should transform both keys and values of a map", function()
            local m = {a = 1, b = 2}
            local key_fn = function(k: string, v: integer): string return k .. v end
            local val_fn = function(k: string, v: integer): string return v .. k end
            local result = maps.full_map(key_fn, val_fn)(m)
            luassert.are_same({a1 = "1a", b2 = "2b"}, result)
        end)
    end)

    describe("get_at and do_get_at", function()
        it("should get a value by key", function()
            local m = {a = 1, b = 2}
            luassert.are_equal(2, maps.do_get_at(m, "b"))
            luassert.are_equal(2, maps.get_at(m)("b"))
            luassert.is_nil(maps.do_get_at(m, "c"))
            luassert.is_nil(maps.get_at(m)("c"))
        end)
    end)

    describe("to_list", function()
        it("should convert map values to a list", function()
            local m = {a = 1, b = 2, c = 3}
            local list = maps.to_list(m)
            table.sort(list)
            luassert.are_same({1, 2, 3}, list)
        end)
    end)

    describe("collect", function()
        it("should create a map from a list", function()
            local record Item
                k: string
                v: integer
            end

            local list: {Item} = {{k = "a", v = 1}, {k = "b", v = 2}}
            local key_fn = function(item: Item): string return item.k end
            local val_fn = function(item: Item): integer return item.v end
            local result = maps.collect(list, key_fn, val_fn)
            luassert.are_same({a = 1, b = 2}, result)
        end)
    end)

    describe("merge", function()
        it("should merge multiple maps, keeping first value for duplicates", function()
            local m1 = {a = 1, b = 2}
            local m2 = {b = 3, c = 4}
            local m3 = {d = 5}
            local merged = maps.merge(m1, m2, m3)
            luassert.are_same({a = 1, b = 2, c = 4, d = 5}, merged)
        end)
    end)

    describe("deep_merge", function()
        it("should merge simple tables", function()
            local m1 = { a = 1, b = 2 }
            local m2 = { c = 3, d = 4 }
            local merged = maps.deep_merge(m1, m2)
            luassert.are_same({ a = 1, b = 2, c = 3, d = 4 }, merged)
        end)

        it("should overwrite non-table values", function()
            local m1 = { a = 1, b = 2 }
            local m2 = { b = 3, c = 4 }
            local merged = maps.deep_merge(m1, m2)
            luassert.are_same({ a = 1, b = 3, c = 4 }, merged)
        end)

        it("should recursively merge nested tables", function()
            local m1 = { a = 1, nested = { x = 10, y = 20 } }
            local m2 = { b = 2, nested = { y = 99, z = 30 } }
            local merged = maps.deep_merge(m1, m2)
            luassert.are_same({ a = 1, b = 2, nested = { x = 10, y = 99, z = 30 } }, merged)
        end)

        it("should overwrite tables over non-table values", function()
            local m1 = { a = 1, b = "not a table" }
            local m2 = { b = { x = 1 } }

            local merged = maps.deep_merge(m1, m2)
            
            luassert.are_same({ a = 1, b = { x = 1 } }, merged)
        end)
    end)
end)
