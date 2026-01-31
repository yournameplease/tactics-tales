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
