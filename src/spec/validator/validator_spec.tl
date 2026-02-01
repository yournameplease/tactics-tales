local type _ = require("busted")
local luassert = require("luassert")
require("spec.picotron_shim")
require("spec.require_trimmer")

local s = require("src.tactics.validator.schema_definition")
local validator = require("src.tactics.validator.schema_validator")

describe("validator", function()
    describe("boolean schema", function()
		local other_types: {string: any} = {
			["string"] = "string-value",
			["integer"] = 42,
			["function"] = function(_: any): any end,
			["dictionary"] = {["key"] = "value"},
			["list"] = {"foo", "bar", "baz"},
			["record"] = { int = 1, boolean = "boolean"},
		} 

		it("required boolean with boolean value is valid", function()
            -- Given
			local schema = s.boolean()
			local data = true

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("required boolean with nil value is invalid", function()
            -- Given
			local schema = s.boolean()
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("required boolean with "..k.." value is invalid", function()
	            -- Given
				local schema = s.boolean()
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end

		it("optional boolean with boolean value is valid", function()
            -- Given
			local schema = s.optional(s.boolean())
			local data = true

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional boolean with nil value is valid", function()
            -- Given
			local schema = s.optional(s.boolean())
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("optional boolean with "..k.." value is invalid", function()
	            -- Given
				local schema = s.optional(s.boolean())
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end
    end)
    describe("string schema", function()
		local other_types: {string: any} = {
			["boolean"] = false,
			["integer"] = 42,
			["function"] = function(_: any): any end,
			["dictionary"] = {["key"] = "value"},
			["list"] = {"foo", "bar", "baz"},
			["record"] = { int = 1, string = "string"},
		} 

		it("required string with string value is valid", function()
            -- Given
			local schema = s.string()
			local data = "value"

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("required string with nil value is invalid", function()
            -- Given
			local schema = s.string()
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("required string with "..k.." value is invalid", function()
	            -- Given
				local schema = s.string()
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end

		it("optional string with string value is valid", function()
            -- Given
			local schema = s.optional(s.string())
			local data = "value"

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional string with nil value is valid", function()
            -- Given
			local schema = s.optional(s.string())
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("optional string with "..k.." value is invalid", function()
	            -- Given
				local schema = s.optional(s.string())
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end
    end)
    describe("integer schema", function()
		local other_types: {string: any} = {
			["boolean"] = false,
			["string"] = "string-value",
			["float"] = 1.1,
			["function"] = function(_: any): any end,
			["dictionary"] = {["key"] = "value"},
			["list"] = {"foo", "bar", "baz"},
			["record"] = { int = 1, string = "string"},
		}
		
		it("required integer with integer value is valid", function()
            -- Given
			local schema = s.integer()
			local data = 42

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("required integer with nil value is invalid", function()
            -- Given
			local schema = s.integer()
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("required integer with "..k.." value is invalid", function()
	            -- Given
				local schema = s.integer()
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end

		it("optional integer with integer value is valid", function()
            -- Given
			local schema = s.optional(s.integer())
			local data = 42

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional integer with nil value is valid", function()
            -- Given
			local schema = s.optional(s.integer())
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("optional integer with "..k.." value is invalid", function()
	            -- Given
				local schema = s.optional(s.integer())
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end
    end)
    describe("function schema", function()
		local other_types: {string: any} = {
			["boolean"] = false,
			["string"] = "string-value",
			["integer"] = 42,
			["dictionary"] = {["key"] = "value"},
			["list"] = {"foo", "bar", "baz"},
			["record"] = { int = 1, string = "string"},
		}
		
		it("required function with function value is valid", function()
            -- Given
			local schema = s.func()
			local data = function(_: string): string end

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("required function with nil value is invalid", function()
            -- Given
			local schema = s.func()
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("required function with "..k.." value is invalid", function()
	            -- Given
				local schema = s.func()
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end

		it("optional function with function value is valid", function()
            -- Given
			local schema = s.optional(s.func())
			local data = function(_: string): string end

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional function with nil value is valid", function()
            -- Given
			local schema = s.optional(s.func())
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("optional function with "..k.." value is invalid", function()
	            -- Given
				local schema = s.optional(s.func())
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end
    end)
    describe("record schema", function()
		local other_types: {string: any} = {
			["boolean"] = false,
			["string"] = "string-value",
			["integer"] = 42,
			["function"] = function(_: any): any end,
			["dictionary"] = {["key"] = "value"},
			["list"] = {"foo", "bar", "baz"},
		}
		
		it("required record with record value is valid", function()
            -- Given
			local schema = s.record({
				string_field = s.string(),
				int_field = s.integer(),
			})
			local data = {
				string_field = "value",
				int_field = 123,
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("required record with nil value is invalid", function()
            -- Given
			local schema = s.record({
				string_field = s.string(),
				int_field = s.integer(),
			})
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required record with bad field value is invalid", function()
            -- Given
			local schema = s.record({
				string_field = s.string(),
				int_field = s.integer(),
			})
			local data = {
				string_field = nil,
				int_field = 42,
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

        it("required record with nil value is invalid", function()
            -- Given
			local schema = s.record({
				string_field = s.string(),
				int_field = s.integer(),
			})
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("required record with "..k.." value is invalid", function()
	            -- Given
				local schema = s.record({
					string_field = s.string(),
					int_field = s.integer(),
				})
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_true(#errors > 0, "Expected at least one error.")
	        end)
		end

		it("optional record with record value is valid", function()
            -- Given
			local schema = s.optional(s.record({
				string_field = s.string(),
				int_field = s.integer(),
			}))
			local data = {
				string_field = "string",
				int_field = 42,
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional record with nil value is valid", function()
            -- Given
			local schema = s.optional(s.record({
				string_field = s.string(),
				int_field = s.integer(),
			}))
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("optional record with "..k.." value is invalid", function()
	            -- Given
				local schema = s.optional(s.record({
					string_field = s.string(),
					int_field = s.integer(),
				}))
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_true(#errors > 0, "Expected at least one error.")
	        end)
		end
    end)
	describe("dictionary schema", function()
		local other_types: {string: any} = {
			["boolean"] = false,
			["string"] = "string-value",
			["integer"] = 42,
			["function"] = function(_: any): any end,
			["list"] = {"foo", "bar", "baz"},
			["record"] = { int = 1, string = "string"},
		}
		
		it("required dictionary with dictionary value is valid", function()
            -- Given
			local schema = s.dictionary(
				s.string(),
				s.integer()
			)
			local data = {
				key_1 = 123,
				key_2 = 456,
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("required dictionary with nil value is invalid", function()
            -- Given
			local schema = s.dictionary(
				s.string(),
				s.integer()
			)
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required dictionary with bad field value is invalid", function()
            -- Given
			local schema = s.dictionary(
				s.string(),
				s.integer()
			)
			local data = {
				key_1 = 123,
				key_2 = "string",
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required dictionary with bad key value is invalid", function()
            -- Given
			local schema = s.dictionary(
				s.string(),
				s.integer()
			)
			local data = {
				key_1 = 123,
				[2] = 456,
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

        it("required dictionary with nil value is invalid", function()
            -- Given
			local schema = s.dictionary(
				s.string(),
				s.integer()
			)
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("required dictionary with "..k.." value is invalid", function()
	            -- Given
				local schema = s.dictionary(
					s.string(),
					s.integer()
				)
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_true(#errors > 0, "Expected at least one error.")
	        end)
		end

		it("optional dictionary with dictionary value is valid", function()
            -- Given
			local schema = s.optional(s.dictionary(
				s.string(),
				s.integer()
			))
			local data = {
				key_1 = 123,
				key_2 = 456,
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional dictionary with nil value is valid", function()
            -- Given
			local schema = s.optional(s.dictionary(
				s.string(),
				s.integer()
			))
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("optional dictionary with "..k.." value is invalid", function()
	            -- Given
				local schema = s.optional(s.dictionary(
					s.string(),
					s.integer()
				))
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_true(#errors > 0, "Expected at least one error.")
	        end)
		end
    end)
	describe("list schema", function()
		local other_types: {string: any} = {
			["boolean"] = false,
			["string"] = "string-value",
			["integer"] = 42,
			["function"] = function(_: any): any end,
		}
		
		it("required list with list value is valid", function()
            -- Given
			local schema = s.list(
				s.string()
			)
			local data = {"foo", "bar", "baz"}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("required list with nil value is invalid", function()
            -- Given
			local schema = s.list(
				s.string()
			)
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required list with bad entry is invalid", function()
            -- Given
			local schema = s.list(
				s.string()
			)
			local data = {"foo", "bar", 123}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required list with list gap is warning", function()
            -- Given
			local schema = s.list(
				s.string()
			)
			local data = {"foo", "bar", [100] = "baz"}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required list with entry before list is warning", function()
            -- Given
			local schema = s.list(
				s.string()
			)
			local data = { [0] = "foo", "bar", "baz"}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required list with non-integer entry is warning", function()
            -- Given
			local schema = s.list(
				s.string()
			)
			local data = { "foo", "bar", ["key"] = "baz"}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("required list with "..k.." value is invalid", function()
	            -- Given
				local schema = s.list(
					s.string()
				)
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_true(#errors > 0, "Expected at least one error.")
	        end)
		end

		it("optional list with list value is valid", function()
            -- Given
			local schema = s.optional(s.list(
				s.string()
			))
			local data = {"foo", "bar", "baz"}

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional list with nil value is valid", function()
            -- Given
			local schema = s.optional(s.list(
				s.string()
			))
			local data = nil

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("optional list with "..k.." value is invalid", function()
	            -- Given
				local schema = s.optional(s.list(
					s.string()
				))
				local data = v

	            -- When
	            local is_valid, errors = validator.validate(data, schema, {})

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_true(#errors > 0, "Expected at least one error.")
	        end)
		end
    end)
    describe("reference schema", function()
		local other_types: {string: any} = {
			["boolean"] = false,
			["string"] = "string-value",
			["integer"] = 42,
			["function"] = function(_: any): any end,
			["dictionary"] = {["key"] = "value"},
			["list"] = {"foo", "bar", "baz"},
			["record"] = { int = 1, string = "string"},
		}
		
		it("required reference key in memory is valid", function()
            -- Given
			local schema = s.reference("memory_table")
			local data = "memory_key"
			local memory = {
				["memory_table"] = {
					["memory_key"] = "memory_value",
				},
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, memory)

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
		it("required reference with key in nested memory is valid", function()
            -- Given
			local schema = s.reference("memory_table_a.memory_table_b")
			local data = "memory_key"
			local memory = {
				["memory_table_a"] = {
					["memory_table_b"] = {
						["memory_key"] = "memory_value",
					},
				},
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, memory)

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("required reference with nil value is invalid", function()
            -- Given
			local schema = s.reference("memory_table")
			local data = nil
			local memory = {
				["memory_table"] = {
					["memory_key"] = "memory_value",
				},
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, memory)

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required reference with value not in memory is invalid", function()
            -- Given
			local schema = s.reference("memory_table")
			local data = "bad_memory_key"
			local memory = {
				["memory_table"] = {
					["memory_key"] = "memory_value",
				},
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, memory)

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)
        it("required reference with non-table value in memory path is invalid", function()
            -- Given
			local schema = s.reference("memory_table_a.memory_table_b")
			local data = "memory_table_a"
			local memory = {
				["memory_table_a"] = "not_a_table",
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, memory)

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("required reference with "..k.." value is invalid", function()
	            -- Given
				local schema = s.reference("memory_table")
				local data = v
				local memory = {
					["memory_table"] = {
						["memory_key"] = "memory_value",
					},
				}

	            -- When
	            local is_valid, errors = validator.validate(data, schema, memory)

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end

		it("optional reference with key in memory is valid", function()
            -- Given
			local schema = s.optional(s.reference("memory_table"))
			local data = "memory_key"
			local memory = {
				["memory_table"] = {
					["memory_key"] = "memory_value",
				},
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, memory)

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional reference with nil value is valid", function()
            -- Given
			local schema = s.optional(s.reference("memory_table_a.memory_table_b"))
			local data = nil
			local memory = {
				["memory_table_a"] = {
					["memory_table_b"] = {
						["memory_key"] = "memory_value",
					},
				},
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, memory)

            -- Then
            luassert.is_true(is_valid, "Expected valid, but got invalid.  Errors: \n\t"..table.concat(errors,"\n\t"))
            luassert.is_equal(0, #errors)
        end)
        it("optional reference with value not in memory is invalid", function()
            -- Given
			local schema = s.optional(s.reference("memory_table"))
			local data = "bad_memory_key"
			local memory = {
				["memory_table"] = {
					["memory_key"] = "memory_value",
				},
			}

            -- When
            local is_valid, errors = validator.validate(data, schema, memory)

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(other_types) do
	        it("optional reference with "..k.." value is invalid", function()
	            -- Given
				local schema = s.optional(s.reference("memory_table"))
				local data = v
				local memory = {
					["memory_table"] = {
						["memory_key"] = "memory_value",
					},
				}

	            -- When
	            local is_valid, errors = validator.validate(data, schema, memory)

	            -- Then
	            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
				luassert.is_equal(1, #errors)
	        end)
		end
    end)
end)

