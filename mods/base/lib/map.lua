local map = {}

---@param file string
---@return StaticMapDefinition
function map.static(file)
    return { type = "static", file = file }
end

return { map = map }
