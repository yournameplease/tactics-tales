global enum MapGenerationType
    "static"
    "procgen"
end

global interface MapDefinition
    type: MapGenerationType
    -- file: string
end

global record StaticMapDefinition
    is MapDefinition
    where self.type == "static"
    file: string
end

global MAP_DEFINITIONS: {string: MapDefinition} = {
    bandit_village = {
        type = "static",
        file = "map/bandit_village.map"
    } as StaticMapDefinition -- is this idiomatic?
}

return MAP_DEFINITIONS