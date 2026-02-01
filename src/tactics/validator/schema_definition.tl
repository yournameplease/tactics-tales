---@brief
--- Defines the functions and data structures used to build
--- validation schemas.

local enum SchemaDefinitionType
	"string"
	"integer"
	"function"
	"dictionary"
	"list"
	"record"
	"reference"
end

local interface SchemaDefinition
	type: SchemaDefinitionType

	optional: boolean
end

local record StringSchemaDefinition
	is SchemaDefinition
	where self.type == "string"
end

local record IntegerSchemaDefinition
	is SchemaDefinition
	where self.type == "integer"
end

local record FunctionSchemaDefinition
	is SchemaDefinition
	where self.type == "function"
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

	StringSchemaDefinition = StringSchemaDefinition,
	IntegerSchemaDefinition = IntegerSchemaDefinition,
	FunctionSchemaDefinition = FunctionSchemaDefinition,
	DictionarySchemaDefinition = DictionarySchemaDefinition,
	ListSchemaDefinition =ListSchemaDefinition,
	RecordSchemaDefinition = RecordSchemaDefinition,
	ReferenceSchemaDefinition = ReferenceSchemaDefinition,
}

function schema_definition.string(): SchemaDefinition
	return {
		type = "string",
		optional = false,
	}
end

function schema_definition.integer(): SchemaDefinition
	return {
		type = "integer",
		optional = false,
	}
end

function schema_definition.func(): SchemaDefinition
	return {
		type = "function",
		optional = false,
	}
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
