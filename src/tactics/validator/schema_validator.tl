---@desc utility class to validate a SchemaDef against arbitrary data
--- Used for modloader validation
local s <const> = require("src.tactics.validator.schema_definition")
local lists <const> = require("src.tactics.util.lists")

local validator = {}

local function validate(
	data: any,
	schema: s.SchemaDefinition,
	memory: any,
	path: {string}
): boolean, {string}
	local is_valid: boolean = true
	local errors: {string} = {}

	local path_string = table.concat(path, ".")

	local add_local_errors = function(errs: {string})
		for _,e in ipairs(errs) do
			pt.add(errors, path_string..": "..e)
		end
	end
	local add_deep_errors = function(errs: {string})
		for _,e in ipairs(errs) do
			pt.add(errors, e)
		end
	end

	do
		if data == nil then
			if not schema.optional then
				is_valid = false
				add_local_errors({
					"Field was a required "..schema.type.." but received nil.",
				})
			end
		else

			if schema is s.StringSchemaDefinition then
				if pt.type(data) ~= "string" then
					is_valid = false
					add_local_errors({
						"Field expected "..schema.type.." but received a "..pt.type(data)
					})
				end
			elseif schema is s.IntegerSchemaDefinition then
				if pt.type(data) ~= "number" then
					is_valid = false
					add_local_errors({
						"Field expected "..schema.type.." but received a "..pt.type(data)
					})
				else
					if math.type(data) ~= "integer" then
						is_valid = false
						add_local_errors({
							"Field expected "..schema.type.." but received a "..math.type(data)
						})
					end
				end
			elseif schema is s.DictionarySchemaDefinition then
				if pt.type(data) ~= "table" then
					is_valid = false
					add_local_errors({
						"Field expected "..schema.type.." but received a "..pt.type(data)
					})
				else
					local key_schema = schema.key
					local value_schema = schema.value
					local data_table: {any: any} = data as {any: any}
					for key,value in pairs(data_table) do
						local key_path = lists.merge(path, {tostring(key)})
						local key_valid, key_errors = validate(
							key,
							key_schema,
							memory,
							key_path
						)
						local value_valid, value_errors = validate(
							value,
							value_schema,
							memory,
							key_path
						)
						is_valid = is_valid and key_valid and value_valid
						add_deep_errors(key_errors)
						add_deep_errors(value_errors)
					end
				end
			elseif schema is s.RecordSchemaDefinition then
				if pt.type(data) ~= "table" then
					is_valid = false
					add_local_errors({
						"Field expected "..schema.type.." but received a "..pt.type(data)
					})
				else
					for field,field_schema in pairs(schema.definition) do
						local data_table: {string: any} = data as {string: any}
						local field_valid, field_errors = validate(
							data_table[field],
							field_schema,
							memory,
							lists.merge(path, {field})
						)
						is_valid = is_valid and field_valid
						add_deep_errors(field_errors)
					end
				end
			elseif schema is s.ReferenceSchemaDefinition then
				if pt.type(data) == "table" then
					is_valid = false
					add_local_errors({
						"Field expected "..schema.type.." but received a "..pt.type(data)
					})
				else
					local current_path: string = nil
					local expected_path = lists.merge(schema.path, {data as string})
					local expected_path_string = table.concat(expected_path, ".")

					local memory_cursor: {string: any} = memory as {string: any} -- type should be or any, but this is easier for the if/else

					if memory_cursor == nil then
						is_valid = false
						add_local_errors({
							"Field expected to find data at `"
								..expected_path_string
								.."` but found nil data at root memory."
						})
					elseif pt.type(memory_cursor) ~= "table" then
						is_valid = false
						add_local_errors({
							"Field expected to find data at `"
								..expected_path_string
								.."` but root memory was not a table."
						})
					else
						for i,p in ipairs(expected_path) do
							current_path = current_path == nil
								and p
								or current_path .. "." .. p

							if memory_cursor[p] == nil then
								is_valid = false
								add_local_errors({
									"Field expected to find data at `"
										..expected_path_string
										.."` but found nil data at `"
										..current_path
										.."`."
								})
								break
							elseif type(memory_cursor[p]) ~= "table" then
								if i < #expected_path then
									is_valid = false
									add_local_errors({
										"Field expected to find data at `"
											..expected_path_string
											.."` but found data "
											..tostring(memory_cursor)
											.." at `"
											..current_path
											.."` which was not a table."
									})
									break
								end
							else
								memory_cursor = memory_cursor[p] as {string: any}
							end
						end
					end
				end
			else
				unexpected(schema.type)
			end
		end
	end
	
	-- todo: Add path info

	return is_valid, errors
end

function validator.validate(
	data: any,
	schema: s.SchemaDefinition,
	memory: any
): boolean, {string}
	return validate(data, schema, memory, {})
end

return validator
