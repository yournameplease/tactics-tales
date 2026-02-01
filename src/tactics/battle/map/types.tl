
---@brief
--- Defines the data structures for map definitions, such as
--- statically defined maps from a file.

local enum MapGenerationType
    "static"
    "procgen"
end

local interface MapDefinition
    type: MapGenerationType
    -- file: string
end

local record StaticMapDefinition
    is MapDefinition
    where self.type == "static"
    file: string
end

local map_types = {
	MapDefinition = MapDefinition,
	StaticMapDefinition = StaticMapDefinition,
}

return map_types
