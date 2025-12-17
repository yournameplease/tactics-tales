local map_types = require("src/tactics/battle/map/types")

local function static_map(file: string): map_types.MapDefinition
    local static_definition: map_types.StaticMapDefinition = {
        type = "static",
        file = file,
    }
    return static_definition
end

local MAP_DEFINITIONS: {string: map_types.MapDefinition} = {
    bandit_village = static_map("map/bandit_village.map"),
    cultist_cave = static_map("map/cultist_cave.map"),
}

return MAP_DEFINITIONS
