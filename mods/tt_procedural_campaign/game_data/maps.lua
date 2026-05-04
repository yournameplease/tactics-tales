---@type ModMapsModule
local MAP_DEFINITIONS = {
    bandit_village    = lib.libs.map.static("map/bandit_village_2.map"),
    cultist_cave      = lib.libs.map.static("map/cultist_cave.map"),
    fortress_town     = lib.libs.map.static("map/fortress_town.map"),
    cliff_crossing    = lib.libs.map.static("map/cliff_crossing.map"),
    castle_defense    = lib.libs.map.static("map/castle_defense.map"),
    playground        = lib.libs.map.static("map/playground.map"),
    model_room        = lib.libs.map.static("map/model_room.map"),
    abandoned_fortress = lib.libs.map.tiled("mods/tt_procedural_campaign/game_data/maps/abandoned_fortress"),
}

return MAP_DEFINITIONS
