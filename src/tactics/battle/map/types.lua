---@brief
--- Defines the data structures for map definitions, such as
--- statically defined maps from a file.

---@alias MapGenerationType "static"|"procgen"

---@class MapDefinition Abstract base for all map definition variants.
---@field type MapGenerationType

---@class StaticMapDefinition : MapDefinition
---@field type "static"
---@field file string Path to the static map file.

return {
}
