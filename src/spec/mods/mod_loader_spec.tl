local type _ = require("busted")
local luassert = require("luassert")
require("spec.picotron_shim")
require("spec.require_trimmer")

local mod_loader = require("src.tactics.mods.mod_loader")

describe("mod_loader", function()
    local pt_include_orig: function(string): any

    before_each(function()
        pt_include_orig = pt.include
    end)

    after_each(function()
        pt.include = pt_include_orig
    end)

    describe("validate_mods", function()
        it("should return true for a valid mod", function()
            -- Given
            pt.include = function(path: string): any
                if path == "mods/test_mod/mod.lua" then
                    return {
                        id = "test_mod",
                        name = "Test Mod",
                        dependencies = { "base" },
                    }
                end
                return {}
            end
            
            local loader = mod_loader.new()
            loader:register_mod("test_mod")

            -- When
            local is_valid, errors = loader:validate_mods()

            -- Then
            luassert.is_true(is_valid)
            luassert.is_equal(0, #errors)
        end)
    end)
end)
