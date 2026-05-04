local map = {}

---@param file string
---@return StaticMapDefinition
function map.static(file)
    return { type = "static", file = file }
end

---@param file string Path to Tiled .lua export (no extension), relative to cart root.
---@return TiledMapDefinition
function map.tiled(file)
    return { type = "tiled", file = file }
end

return { map = map }
