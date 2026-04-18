---@brief
--- Defines the functions and data structures used to build
--- validation schemas.

---@alias SchemaDefinitionType "type"|"dictionary"|"list"|"record"|"reference"|"factory"

---@class SchemaDefinition Abstract base for all schema definitions.
---@field type SchemaDefinitionType Discriminator for the schema variant.
---@field optional boolean When true, nil values are accepted.

---@class TypeSchemaDefinition : SchemaDefinition
---@field type "type"
---@field pt_type string Lua type string as returned by `type()`.
---@field math_type? string Math subtype as returned by `math.type()`; nil if unconstrained.

---@class DictionarySchemaDefinition : SchemaDefinition
---@field type "dictionary"
---@field key SchemaDefinition Schema for dictionary keys.
---@field value SchemaDefinition Schema for dictionary values.

---@class ListSchemaDefinition : SchemaDefinition
---@field type "list"
---@field element SchemaDefinition Schema for each list element.

---@class RecordSchemaDefinition : SchemaDefinition
---@field type "record"
---@field definition table<string, SchemaDefinition> Field name to schema mapping.

---@class ReferenceSchemaDefinition : SchemaDefinition
---@field type "reference"
---@field path string[] Dot-separated path segments used to look up the referenced value.

---@class FactorySchemaDefinition : SchemaDefinition
---@field type "factory"

local schema_definition = {}

--- Create a schema that requires a boolean value.
---@return SchemaDefinition
function schema_definition.boolean()
    ---@type TypeSchemaDefinition
    local self = {
        type = "type",
        optional = false,
        pt_type = "boolean",
    }
    return self
end

--- Create a schema that requires a string value.
---@return SchemaDefinition
function schema_definition.string()
    ---@type TypeSchemaDefinition
    local self = {
        type = "type",
        optional = false,
        pt_type = "string",
    }
    return self
end

--- Create a schema that requires an integer value.
---@return SchemaDefinition
function schema_definition.integer()
    ---@type TypeSchemaDefinition
    local self = {
        type = "type",
        optional = false,
        pt_type = "number",
        math_type = "integer",
    }
    return self
end

--- Create a schema that requires a function value.
---@return SchemaDefinition
function schema_definition.func()
    ---@type TypeSchemaDefinition
    local self = {
        type = "type",
        optional = false,
        pt_type = "function",
    }
    return self
end

--- Mark an existing schema as optional so nil values are accepted.
---@param s SchemaDefinition Schema to make optional.
---@return SchemaDefinition
function schema_definition.optional(s)
    s.optional = true
    return s
end

--- Create a schema that requires a table with the given named fields.
---@param def table<string, SchemaDefinition> Map of field names to their schemas.
---@return SchemaDefinition
function schema_definition.record(def)
    ---@type RecordSchemaDefinition
    local self = {
        type = "record",
        optional = false,
        definition = def,
    }
    return self
end

--- Create a schema that requires a table with uniform key and value types.
---@param key SchemaDefinition Schema for keys.
---@param value SchemaDefinition Schema for values.
---@return SchemaDefinition
function schema_definition.dictionary(key, value)
    ---@type DictionarySchemaDefinition
    local self = {
        type = "dictionary",
        optional = false,
        key = key,
        value = value,
    }
    return self
end

--- Create a schema that requires an array with uniform element types.
---@param element SchemaDefinition Schema for each element.
---@return SchemaDefinition
function schema_definition.list(element)
    ---@type ListSchemaDefinition
    local self = {
        type = "list",
        optional = false,
        element = element,
    }
    return self
end

--- Create a schema that requires a function (factory).
---@return SchemaDefinition
function schema_definition.factory()
    ---@type FactorySchemaDefinition
    local self = {
        type = "factory",
        optional = false,
    }
    return self
end

--- Create a schema that validates a value by traversing `memory` along the given path.
---@param path string Dot-separated path string (e.g. "maps.castle") to the referenced entry.
---@return SchemaDefinition
function schema_definition.reference(path)
    local path_string = {}
    for word in string.gmatch(path, "[%a_]+") do
        table.insert(path_string, word)
    end
    ---@type ReferenceSchemaDefinition
    local self = {
        type = "reference",
        optional = false,
        path = path_string,
    }
    return self
end

return schema_definition
