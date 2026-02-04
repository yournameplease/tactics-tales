local function static_map(file)
    local static_definition = {
        type = "static",
        file = file,
    }
    return static_definition
end

local MAP_DEFINITIONS = {
    bandit_village = static_map("map/bandit_village_2.map"),
    cultist_cave = static_map("map/cultist_cave.map"),
    fortress_town = static_map("map/fortress_town.map"),
    cliff_crossing = static_map("map/cliff_crossing.map"),
    evil_castle = static_map("map/evil_castle.map"),
    playground = static_map("map/playground.map"),
}

return MAP_DEFINITIONS
