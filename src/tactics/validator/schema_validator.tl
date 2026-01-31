---@desc utility class to validate a SchemaDef against arbitrary data
--- Used for modloader validation
local s <const> = require("src.tactics.validator.schema_definition")

local validator = {}

local function validate(
	data: any,
	schema: s.SchemaDefinition,
	memory: any,
	path: {string}
): boolean, {string}
	local is_valid: boolean = true
	local errors: {string} = {}

	do
		if data == nil then
			if not schema.optional then
				is_valid = false
				pt.add(errors, 
					"Field was a required "..schema.type.." but received nil."
				)
			end
		else

			if schema is s.StringSchemaDefinition then
				if pt.type(data) ~= "string" then
					is_valid = false
					pt.add(errors, 
						"Field expected "..schema.type.." but received a "..pt.type(data)
					)
				end
			elseif schema is s.IntegerSchemaDefinition then
				if pt.type(data) ~= "number" then
					is_valid = false
					pt.add(errors, 
						"Field expected "..schema.type.." but received a "..pt.type(data)
					)
				else
					if math.type(data) ~= "integer" then
						is_valid = false
						pt.add(errors, 
							"Field expected "..schema.type.." but received a "..math.type(data)
					)
					end
				end
			elseif schema is s.DictionarySchemaDefinition then

			elseif schema is s.RecordSchemaDefinition then

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
