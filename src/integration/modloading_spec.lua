local luassert = require("luassert")

local mod_loader = require("src.tactics.mods.mod_loader")

describe("included mods #it", function()
    describe("base mod", function()
        it("should be valid", function()
            -- Given
            local loader = mod_loader.new()
            loader:register_mod("base")
            loader:register_mod("tactics_puzzler")
            loader:register_mod("tt_fantasy_demo_story")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
    end)
end)
