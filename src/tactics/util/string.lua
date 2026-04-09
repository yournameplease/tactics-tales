---@brief
--- Contains string manipulation utility functions.

local str = {}

--- Populate `{key}` placeholders in a template string with values from a map.
---@param template string Template string containing `{key}`-style placeholders.
---@param values table<string, any> Map of placeholder names to their replacement values.
---@return string
function str.format(template, values)
    local out = template
    for k, v in pairs(values) do
        out = out:gsub("{" .. k .. "}", tostring(v))
    end
    return out
end

return str
