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
---@param tileset_name string? Tileset stem for gfx_registry lookup (e.g. "paper_tileset").
---@param objective string? Battle objective ("kill_boss", "escape", "rout"). Defaults to "rout".
---@return ProcgenMapDefinition
function map.procgen(theme, chunks, tileset_name, objective)
    return { type = "procgen", theme = theme, chunks = chunks, tileset_name = tileset_name, objective = objective }
end

return { map = map }
