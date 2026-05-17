---@type ModMapsModule
local MAP_DEFINITIONS = {
    bandit_village     = lib.libs.map.static("map/bandit_village_2.map"),
    cultist_cave       = lib.libs.map.static("map/cultist_cave.map"),
    fortress_town      = lib.libs.map.static("map/fortress_town.map"),
    cliff_crossing     = lib.libs.map.static("map/cliff_crossing.map"),
    castle_defense     = lib.libs.map.static("map/castle_defense.map"),
    playground         = lib.libs.map.static("map/playground.map"),
    model_room         = lib.libs.map.static("map/model_room.map"),
    abandoned_fortress = lib.libs.map.tiled("mods/tt_procedural_campaign/game_data/maps/abandoned_fortress"),
    village_overrun = lib.libs.map.tiled("mods/tt_procedural_campaign/game_data/maps/village_overrun"),
    cavern_fortress = lib.libs.map.tiled("mods/tt_procedural_campaign/game_data/maps/cavern_fortress"),
    castle_escape       = lib.libs.map.tiled("mods/tt_procedural_campaign/game_data/maps/castle_escape"),
    procedural_castle   = lib.libs.map.procgen("castle", "mods/tt_procedural_campaign/game_data/chunks/castle.chunks", "paper_tileset"),
    procedural_cave   = lib.libs.map.procgen("cave", "mods/tt_procedural_campaign/game_data/chunks/cave.chunks", "paper_tileset"),
}

return MAP_DEFINITIONS
