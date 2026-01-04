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
}

return MAP_DEFINITIONS
