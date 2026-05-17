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

---@param theme string Theme name (e.g. "castle").
---@param chunks string Path to the .chunks file.
---@return ProcgenMapDefinition
function map.procgen(theme, chunks)
    return { type = "procgen", theme = theme, chunks = chunks }
end

return { map = map }
