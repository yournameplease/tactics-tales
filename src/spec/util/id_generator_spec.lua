local luassert <const> = require("luassert")

local id_generator = require("src.tactics.util.id_generator")

describe("tactics.util.id_generator", function()
    it("should start with ID 1", function()
        local generator = id_generator.new()
        luassert.are_equal(1, generator:get_id())
    end)

    it("should generate sequential IDs", function()
        local generator = id_generator.new()
        luassert.are_equal(1, generator:get_id())
        luassert.are_equal(2, generator:get_id())
        luassert.are_equal(3, generator:get_id())
    end)

    it("should have independent generators", function()
        local gen1 = id_generator.new()
        local gen2 = id_generator.new()

        luassert.are_equal(1, gen1:get_id())
        luassert.are_equal(1, gen2:get_id())
        luassert.are_equal(2, gen1:get_id())
        luassert.are_equal(2, gen2:get_id())
    end)
end)
