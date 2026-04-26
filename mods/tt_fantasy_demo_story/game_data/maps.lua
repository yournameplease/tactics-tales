local function static_map(file)
    local static_definition = {
        type = "static",
        file = file,
    }
    return static_definition
end

---@type ModMapsModule
local MAP_DEFINITIONS = {
    bandit_village = static_map("map/bandit_village_2.map"),
    cultist_cave = static_map("map/cultist_cave.map"),
    fortress_town = static_map("map/fortress_town.map"),
    cliff_crossing = static_map("map/cliff_crossing.map"),
    castle_defense = static_map("map/castle_defense.map"),
    playground = static_map("map/playground.map"),
    model_room = static_map("map/model_room.map"),
    test_large = {
        type = "flat",
        width = 32,
        height = 32,
        spawn_metatiles = {
            [0x01] = { x = 2,  y = 15 },
            [0x02] = { x = 28, y = 15 },
        },
    },
}

return MAP_DEFINITIONS
