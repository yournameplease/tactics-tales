---@brief
--- Contains string manipulation utility functions.

local str = {}

--- Populate "{key}" strings with values from the map
---@param template string
---@param values table<string, any>
---@return string
function str.format(template, values)
    local out = template
    for k, v in pairs(values) do
        out = out:gsub("{" .. k .. "}", tostring(v))
    end
    return out
end

return str
