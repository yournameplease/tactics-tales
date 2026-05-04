local luassert = require("luassert")

local mod_schema = require("src.tactics.mods.mod_schema")
local validator = require("src.tactics.validator.schema_validator")

describe("mod_schema", function()
    describe("mod_content", function()
        it("accepts a content block with a gfx list", function()
            -- Given
            local content = {
                maps = "game_data/maps",
                gfx = { "game_data/gfx/tiny_tileset" },
                default_campaign = "test_campaign",
            }

            -- When
            local is_valid, errors = validator.validate(content, mod_schema.mod_content, {})

            -- Then
            luassert.is_true(is_valid)
            luassert.are_equal(0, #errors, "Got errors:\n\t"..table.concat(errors, "\n\t"))
        end)

        it("accepts a content block without a gfx field", function()
            -- Given
            local content = {
                maps = "game_data/maps",
                default_campaign = "test_campaign",
            }

            -- When
            local is_valid, errors = validator.validate(content, mod_schema.mod_content, {})

            -- Then
            luassert.is_true(is_valid)
            luassert.are_equal(0, #errors, "Got errors:\n\t"..table.concat(errors, "\n\t"))
        end)
    end)
end)
