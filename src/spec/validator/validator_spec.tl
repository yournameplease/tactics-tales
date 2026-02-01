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
	["reference"] = nil, -- this would collide with string or integer
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

		for k,v in pairs(sample_values) do
			if k ~= "string" and v ~= nil then
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

		for k,v in pairs(sample_values) do
			if k ~= "string" and v ~= nil then
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
		end
    end)
    describe("integer schema", function()
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
        it("required integer with float value is invalid", function()
            -- Given
			local schema = s.integer()
			local data = 0.5

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(sample_values) do
			if k ~= "integer" and v ~= nil then
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
        it("optional integer with float value is invalid", function()
            -- Given
			local schema = s.optional(s.integer())
			local data = 0.5

            -- When
            local is_valid, errors = validator.validate(data, schema, {})

            -- Then
            luassert.is_false(is_valid, "Expected invalid, but got valid.  Errors: \n\t"..table.concat(errors,"\n\t"))
			luassert.is_equal(1, #errors)
        end)

		for k,v in pairs(sample_values) do
			if k ~= "integer" and v ~= nil then
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
		end
    end)
    describe("record schema", function()
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

		for k,v in pairs(sample_values) do
			if k ~= "record" and v ~= nil then
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

		for k,v in pairs(sample_values) do
			if k ~= "record" and v ~= nil then
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
		end
    end)
	describe("dictionary schema", function()
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

		for k,v in pairs(sample_values) do
			if k ~= "dictionary" and v ~= nil then
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

		for k,v in pairs(sample_values) do
			if k ~= "dictionary" and v ~= nil then
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
		end
    end)
    describe("reference schema", function()
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

		for k,v in pairs(sample_values) do
			if k ~= "reference" and v ~= nil then
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

		for k,v in pairs(sample_values) do
			if k ~= "reference" and v ~= nil then
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
		end
    end)
end)

