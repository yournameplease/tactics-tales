local type _ = require("busted")
local luassert = require("luassert")
require("spec.picotron_shim")
require("spec.require_trimmer")

local s = require("src.tactics.validator.schema_definition")
local validator = require("src.tactics.validator.schema_validator")

local sample_values <total>: {s.SchemaDefinitionType: any} = {
	["string"] = "string-value",
	["integer"] = 42,
	["dictionary"] = {["key"] = "value"},
	["record"] = { int = 1, string = "string"},
} 


describe("validator", function()
    describe("string schema", function()
		it("required string with string value is valid", function()
            -- Given
			local schema = s.string()
			local data = "value"

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid)
            luassert.is_equal(0, #errors)
        end)
        it("required string with nil value is invalid", function()
            -- Given
			local schema = s.string()
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid)
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(sample_values) do
			if k ~= "string" then
		        it("required string with "..k.." value is invalid", function()
		            -- Given
					local schema = s.string()
					local data = v

		            -- When
		            local is_valid, errors = validator.validate(data, schema, {})

		            -- Then
		            luassert.is_false(is_valid)
					luassert.is_equal(1, #errors)
		        end)
			end
		end

		it("optional string with string value is valid", function()
            -- Given
			local schema = s.string()
			local data = "value"

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid)
            luassert.is_equal(0, #errors)
        end)
        it("optional string with nil value is valid", function()
            -- Given
			local schema = s.string()
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid)
            luassert.is_equal(0, #errors)
        end)

		for k,v in pairs(sample_values) do
			if k ~= "string" then
		        it("optional string with "..k.." value is invalid", function()
		            -- Given
					local schema = s.string()
					local data = v

		            -- When
		            local is_valid, errors = validator.validate(data, schema, {})

		            -- Then
		            luassert.is_false(is_valid)
					luassert.is_equal(1, #errors)
		        end)
			end
		end
    end)
end)

