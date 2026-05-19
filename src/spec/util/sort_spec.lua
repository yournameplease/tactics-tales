local luassert = require("luassert")

local sort = require("src.tactics.util.sort")

describe("tactics.util.sort", function()
    describe("by", function()
        it("sorts a list of integers in ascending order by default", function()
            local list = { 3, 1, 4, 1, 5 }
            sort.by(list)
            luassert.are_same({ 1, 1, 3, 4, 5 }, list)
        end)

        it("sorts in descending order with a custom comparator", function()
            local list = { 3, 1, 4 }
            sort.by(list, function(a, b) return a > b end)
            luassert.are_same({ 4, 3, 1 }, list)
        end)

        it("leaves a single-element list unchanged", function()
            local list = { 7 }
            sort.by(list)
            luassert.are_same({ 7 }, list)
        end)

        it("leaves an empty list unchanged", function()
            local list = {}
            sort.by(list)
            luassert.are_same({}, list)
        end)

        it("sorts a list of tables by a field", function()
            local list = { { v = 3 }, { v = 1 }, { v = 2 } }
            sort.by(list, function(a, b) return a.v < b.v end)
            luassert.are_same({ { v = 1 }, { v = 2 }, { v = 3 } }, list)
        end)
    end)
end)
