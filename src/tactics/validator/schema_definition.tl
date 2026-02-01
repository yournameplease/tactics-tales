---@brief
--- Defines the functions and data structures used to build
--- validation schemas.

local enum SchemaDefinitionType
	"type"
	"dictionary"
	"list"
	"record"
	"reference"
end

local interface SchemaDefinition
	type: SchemaDefinitionType

	optional: boolean
end

-- for types which only need simply type checks
local record TypeSchemaDefinition
	is SchemaDefinition
	where self.type == "type"
	pt_type: string
	math_type: string
end

local record DictionarySchemaDefinition
	is SchemaDefinition
	where self.type == "dictionary"
	key: SchemaDefinition
	value: SchemaDefinition
end

local record ListSchemaDefinition
	is SchemaDefinition
	where self.type == "list"
	element: SchemaDefinition
end

local record RecordSchemaDefinition
	is SchemaDefinition
	where self.type == "record"
	definition: {string: SchemaDefinition}
end

local record ReferenceSchemaDefinition
	is SchemaDefinition
	where self.type == "reference"
	path: {string}
end

local schema_definition = {
	SchemaDefinitionType = SchemaDefinitionType,
	SchemaDefinition = SchemaDefinition,	

	TypeSchemaDefinition = TypeSchemaDefinition,
	DictionarySchemaDefinition = DictionarySchemaDefinition,
	ListSchemaDefinition =ListSchemaDefinition,
	RecordSchemaDefinition = RecordSchemaDefinition,
	ReferenceSchemaDefinition = ReferenceSchemaDefinition,
}

function schema_definition.boolean(): SchemaDefinition
	local self: TypeSchemaDefinition = {
		type = "type",
		optional = false,
		pt_type = "string",
	}
	return self
end

function schema_definition.boolean(): SchemaDefinition
	local self: TypeSchemaDefinition = {
		type = "type",
		optional = false,
		pt_type = "boolean",
	}
	return self
end

function schema_definition.string(): SchemaDefinition
	local self: TypeSchemaDefinition = {
		type = "type",
		optional = false,
		pt_type = "string",
	}
	return self
end

function schema_definition.integer(): SchemaDefinition
	local self: TypeSchemaDefinition = {
		type = "type",
		optional = false,
		pt_type = "number",
		math_type = "integer",
	}
	return self
end

function schema_definition.func(): SchemaDefinition
	local self: TypeSchemaDefinition = {
		type = "type",
		optional = false,
		pt_type = "function",
	}
	return self
end

function schema_definition.optional(s: SchemaDefinition): SchemaDefinition
	s.optional = true
	return s
end

function schema_definition.record(def: {string: SchemaDefinition}): SchemaDefinition
	local self: RecordSchemaDefinition = {
		type = "record",
		optional = false,
		definition = def,
	}
	return self
end

function schema_definition.dictionary(
	key: SchemaDefinition,
	value: SchemaDefinition
): SchemaDefinition
	local self: DictionarySchemaDefinition = {
		type = "dictionary",
		optional = false,
		key = key,
		value = value,
	}
	return self
end

function schema_definition.list(
	element: SchemaDefinition
): SchemaDefinition
	local self: ListSchemaDefinition = {
		type = "list",
		optional = false,
		element = element,
	}
	return self
end

function schema_definition.reference(
	path: string
): SchemaDefinition
	local path_string = {}
	for word in string.gmatch(path, "[%a_]+") do
		pt.add(path_string, word)
	end
	
	local self: ReferenceSchemaDefinition = {
		type = "reference",
		path = path_string,
	}
	return self
end

return schema_definition
