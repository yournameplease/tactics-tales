local type _ = require("busted")
local luassert = require("luassert")
require("spec.require_trimmer")
require("spec.picotron_shim")

local mod_loader = require("src.tactics.mods.mod_loader")

describe("included mods #it", function()
    describe("base mod", function()
        it("should be valid", function()
            -- Given
            local loader = mod_loader.new()
            loader:register_mod("base")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_true(is_valid)
            luassert.is_equal(0, #errors)
        end)
    end)
end)

