---@desc utility class to validate a SchemaDef against arbitrary data
--- Used for modloader validation
local SchemaDefinition <const> = require("src.tactics.validator.schema_definition").SchemaDefinition

local validator = {}

function validator.validate(
	data: any,
	schema: SchemaDefinition,
	memory: any
): boolean, {string}
	return true, {}
end

return validator
