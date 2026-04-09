---@brief
--- The core implementation of the schema validator.
--- Traverses a data structure and checks it against a schema definition.

local lists = require("src.tactics.util.lists")

local validator = {}

---@param data any Value being validated.
---@param schema SchemaDefinition Schema to validate against.
---@param memory any Root memory table for reference validation.
---@param path string[] Current path segments used to prefix error messages.
---@return boolean ok
---@return string[] errors
local function validate(data, schema, memory, path)
    log.debug("validating schema " .. schema.type .. " for data " .. tostring(data))

    local is_valid = true
    local errors = {}

    local path_string = table.concat(path, ".")

    local add_local_errors = function(errs)
        for _, e in ipairs(errs) do
            table.insert(errors, path_string .. ": " .. e)
        end
    end
    local add_deep_errors = function(errs)
        for _, e in ipairs(errs) do
            table.insert(errors, e)
        end
    end

    do
        if data == nil then
            if not schema.optional then
                is_valid = false
                add_local_errors({
                    "Field was a required " .. schema.type .. " but received nil.",
                })
            end
        else
            if schema.type == "type" then
                ---@cast schema TypeSchemaDefinition
                if type(data) ~= schema.pt_type then
                    is_valid = false
                    add_local_errors({
                        "Field expected " .. schema.type .. " but received a " .. type(data)
                    })
                else
                    if schema.math_type and math.type(data) ~= schema.math_type then
                        is_valid = false
                        add_local_errors({
                            "Field expected " .. schema.type .. " but received a " .. math.type(data)
                        })
                    end
                end
            elseif schema.type == "dictionary" then
                ---@cast schema DictionarySchemaDefinition
                if type(data) ~= "table" then
                    is_valid = false
                    add_local_errors({
                        "Field expected " .. schema.type .. " but received a " .. type(data)
                    })
                else
                    local key_schema = schema.key
                    local value_schema = schema.value
                    for key, value in pairs(data) do
                        local key_path = lists.merge(path, { tostring(key) })
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
            elseif schema.type == "list" then
                ---@cast schema ListSchemaDefinition
                if type(data) ~= "table" then
                    is_valid = false
                    add_local_errors({
                        "Field expected " .. schema.type .. " but received a " .. type(data)
                    })
                else
                    local element_schema = schema.element
                    local data_list = data
                    for i, value in ipairs(data_list) do
                        local element_path = lists.merge(path, { "[" .. i .. "]" })
                        local element_valid, element_errors = validate(
                            value,
                            element_schema,
                            memory,
                            element_path
                        )
                        is_valid = is_valid and element_valid
                        add_deep_errors(element_errors)
                    end
                    for k, _ in pairs(data) do
                        if type(k) ~= "number"
                            or math.type(k) ~= "integer"
                        then
                            add_local_errors({
                                "Field expected " .. schema.type
                                .. " but found a non-integer key "
                                .. tostring(k)
                            })
                        else
                            local int = k
                            if int > #data_list or int <= 0 then
                                add_local_errors({
                                    "Field expected " .. schema.type
                                    .. " but found an integer "
                                    .. int
                                    .. " not in the list's range."
                                })
                            end
                        end
                    end
                end
            elseif schema.type == "record" then
                ---@cast schema RecordSchemaDefinition
                if type(data) ~= "table" then
                    is_valid = false
                    add_local_errors({
                        "Field expected " .. schema.type .. " but received a " .. type(data)
                    })
                else
                    for field, field_schema in pairs(schema.definition) do
                        local field_valid, field_errors = validate(
                            data[field],
                            field_schema,
                            memory,
                            lists.merge(path, { field })
                        )
                        is_valid = is_valid and field_valid
                        add_deep_errors(field_errors)
                    end
                end
            elseif schema.type == "reference" then
                ---@cast schema ReferenceSchemaDefinition
                if type(data) == "table" or type(data) == "function" then
                    is_valid = false
                    add_local_errors({
                        "Field expected " .. schema.type .. " but received a " .. type(data)
                    })
                else
                    local current_path = nil
                    local expected_path = lists.merge(schema.path, { tostring(data) })
                    local expected_path_string = table.concat(expected_path, ".")

                    local memory_cursor = memory

                    if memory_cursor == nil then
                        is_valid = false
                        add_local_errors({
                            "Field expected to find data at `"
                                .. expected_path_string
                                .. "` but found nil data at root memory."
                        })
                    elseif type(memory_cursor) ~= "table" then
                        is_valid = false
                        add_local_errors({
                            "Field expected to find data at `"
                                .. expected_path_string
                                .. "` but root memory was not a table."
                        })
                    else
                        for i, p in ipairs(expected_path) do
                            current_path = current_path == nil
                                and p
                                or current_path .. "." .. p

                            if memory_cursor[p] == nil then
                                is_valid = false
                                add_local_errors({
                                    "Field expected to find data at `"
                                        .. expected_path_string
                                        .. "` but found nil data at `"
                                        .. current_path
                                        .. "`."
                                })
                                break
                            elseif type(memory_cursor[p]) ~= "table" then
                                if i < #expected_path then
                                    is_valid = false
                                    add_local_errors({
                                        "Field expected to find data at `"
                                            .. expected_path_string
                                            .. "` but found data "
                                            .. tostring(memory_cursor)
                                            .. " at `"
                                            .. current_path
                                            .. "` which was not a table."
                                    })
                                    break
                                end
                            else
                                memory_cursor = memory_cursor[p]
                            end
                        end
                    end
                end
            else
                error("unexpected schema type: " .. tostring(schema.type))
            end
        end
    end

    -- todo: Add path info

    return is_valid, errors
end

--- Validate `data` against `schema`, using `memory` to resolve references.
---@param data any Value to validate.
---@param schema SchemaDefinition Schema to validate against.
---@param memory any Root memory table for reference validation.
---@return boolean ok
---@return string[] errors
function validator.validate(data, schema, memory)
    return validate(data, schema, memory, {})
end

return validator
