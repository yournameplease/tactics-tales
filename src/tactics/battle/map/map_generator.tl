require("src/tactics/types")
require("src/tactics/data/maps")
require("src/tactics/battle/battle_map")
local MAP_DEFINITIONS = require("src/tactics/data/maps")
local map_types = require("src/tactics/battle/map/types")


local map_generator = {
    
}

local record __MapFetchResultEntry
    bmp: Userdata
end

local type MapFetchResult = { __MapFetchResultEntry }



local BASE_PLAYER_SPAWNER_SPRITE = 0x408
local BASE_ENEMY_SPAWNER_SPRITE = 0x410
local BASE_REINFORCEMENT_SPAWNER_SPRITE = 0x418

local METATILES_LAYER = 1
local FRONT_WALL_LAYER = 2
local MID_WALL_LAYER = 3
local BACK_WALL_LAYER = 4
local GROUND_LAYER = 5

local function as_map(battle_map: MapFetchResult): MapLayers
    return {
        metatiles = battle_map[METATILES_LAYER].bmp,
        front_wall = battle_map[FRONT_WALL_LAYER].bmp,
        mid_wall = battle_map[MID_WALL_LAYER].bmp,
        back_wall = battle_map[BACK_WALL_LAYER].bmp,
        ground = battle_map[GROUND_LAYER].bmp
    }
end

local function apply_checkerboard(map_layers: MapLayers)
    local ground = map_layers.ground
    for x = 0,ground:height()-1 do
        for y = 0,ground:width()-1 do
            local tile = ground:get(x, y)
            if x+y & 1 == 0 and pt.fget(tile) & 0x40 == 0x40 then
                ground:set(x, y, tile+1)
            end  
        end
    end
end

local function apply_default_walls(map_layers: MapLayers)
    local ground = map_layers.ground
    local back_wall = map_layers.back_wall
    -- mid wall makes ui look ugly
    -- local mid_wall = map_layers.mid_wall
    local front_wall = map_layers.front_wall
    for x = 0,ground:height()-1 do
        for y = 0,ground:width()-1 do
            local tile = ground:get(x, y)
            if pt.fget(tile) & 0x80 == 0x80 then
                if back_wall:get(x,y) == 0 then
                    back_wall:set(x,y,tile+2)
                end
                -- if mid_wall:get(x,y) == 0 then
                --     mid_wall:set(x,y,tile+2)
                -- end
                if front_wall:get(x,y) == 0 then
                    front_wall:set(x,y,tile+2)
                end
            end  
        end
    end
end

local function load_static(definition: map_types.StaticMapDefinition): BattleMap
    local map_fetch = pt.fetch(DATP..definition.file) as MapFetchResult

    local layers = as_map(map_fetch)
    
    apply_checkerboard(layers)
    apply_default_walls(layers)

    local metatiles_layer = layers.metatiles
    local battle_map: BattleMap = BattleMap.new(metatiles_layer:width(), metatiles_layer:height())
    battle_map.layers = layers
    battle_map.width = metatiles_layer:width()
    battle_map.height = metatiles_layer:height()
    battle_map.metadata = {
        player_spawners = {},
        enemy_spawners = {},
    }

    for x = 0, metatiles_layer:height()-1 do
        for y = 0,metatiles_layer:width()-1 do
            local tile = metatiles_layer:get(x, y)
            if tile >= BASE_PLAYER_SPAWNER_SPRITE and tile < BASE_ENEMY_SPAWNER_SPRITE then
                local player_spawner_id = tile - BASE_PLAYER_SPAWNER_SPRITE + 1
                battle_map.metadata.player_spawners[player_spawner_id] = TilePoint.of(x, y)
            elseif tile >= BASE_ENEMY_SPAWNER_SPRITE and tile < BASE_REINFORCEMENT_SPAWNER_SPRITE then
                local enemy_spawner_id = tile - BASE_ENEMY_SPAWNER_SPRITE + 1
                if battle_map.metadata.enemy_spawners[enemy_spawner_id] == nil then
                    battle_map.metadata.enemy_spawners[enemy_spawner_id] = {}
                end
                pt.add(battle_map.metadata.enemy_spawners[enemy_spawner_id], TilePoint.of(x, y))
            end
        end
    end

    return battle_map
end

-- function MapGenerator:_generate_procedural(definition) end

--- Returns a grid table and metadata table
-- @param map_def: The entry from MAP_DEFINITIONS
-- @return map: The Picotron map data
-- @return meta: table containing { events={} }
function map_generator.load_map(map_id: string): BattleMap
    local definition = MAP_DEFINITIONS[map_id]
    assert(definition ~= nil)

    local battle_map: BattleMap
    if definition is map_types.StaticMapDefinition then
        battle_map = load_static(definition)
    -- elseif definition is ProceduralMapDefinition then

    else
        error("unknown map type")
    end

    return battle_map
end

return map_generator
