local luassert = require("luassert")

local string_util = require("src.tactics.util.string")

describe("tactics.util.string", function()
    describe("format", function()
        it("should replace placeholders with values from a map", function()
            local template = "Hello, {name}! Welcome to {place}."
            local values = { name = "World", place = "Earth" }
            local result = string_util.format(template, values)
            luassert.are_equal("Hello, World! Welcome to Earth.", result)
        end)

        it("should handle multiple occurrences of the same placeholder", function()
            local template = "{a} + {a} = {b}"
            local values = { a = 1, b = 2 }
            local result = string_util.format(template, values)
            luassert.are_equal("1 + 1 = 2", result)
        end)

        it("should handle no-op if no placeholders match", function()
            local template = "No placeholders here."
            local values = { name = "World" }
            local result = string_util.format(template, values)
            luassert.are_equal("No placeholders here.", result)
        end)

        it("should leave placeholders if value not in map", function()
            local template = "Hello, {name}!"
            local values = { user = "test" }
            local result = string_util.format(template, values)
            luassert.are_equal("Hello, {name}!", result)
        end)

        it("should handle number values", function()
            local template = "Score: {score}"
            local values = { score = 100 }
            local result = string_util.format(template, values)
            luassert.are_equal("Score: 100", result)
        end)
    end)
end)
