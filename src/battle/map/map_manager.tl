require("src/types")
require("src/data/maps")
local MapData = require("src/battle/map/battle_map")

global record MapManager

end

global record __MapFetchResultEntry
    bmp: Userdata
end

global type MapFetchResult = { __MapFetchResultEntry }


local BASE_PLAYER_SPAWNER_SPRITE = 0x408
local BASE_ENEMY_SPAWNER_SPRITE = 0x410
local BASE_REINFORCEMENT_SPAWNER_SPRITE = 0x418

local METATILES_LAYER = 1
local FRONT_WALL_LAYER = 2
local MID_WALL_LAYER = 3
local BACK_WALL_LAYER = 4
local GROUND_LAYER = 5
-- map_data
--

function MapManager:as_map(map_data: MapFetchResult): MapLayers
    return {
        metatiles = map_data[METATILES_LAYER].bmp,
        front_wall = map_data[FRONT_WALL_LAYER].bmp,
        mid_wall = map_data[MID_WALL_LAYER].bmp,
        back_wall = map_data[BACK_WALL_LAYER].bmp,
        ground = map_data[GROUND_LAYER].bmp
    }
end

function MapManager:apply_checkerboard(map_layers: MapLayers)
    local ground = map_layers.ground
    for x = 0,ground:height()-1 do
        for y = 0,ground:width()-1 do
            local tile = ground:get(x, y)
            if x+y & 1 == 0 and fget(tile) & 0x40 == 0x40 then
                ground:set(x, y, tile+1)
            end  
        end
    end
end

function MapManager:apply_default_walls(map_layers: MapLayers)
    local ground = map_layers.ground
    local back_wall = map_layers.back_wall
    local mid_wall = map_layers.mid_wall
    local front_wall = map_layers.front_wall
    for x = 0,ground:height()-1 do
        for y = 0,ground:width()-1 do
            local tile = ground:get(x, y)
            if fget(tile) & 0x80 == 0x80 then
                if back_wall:get(x,y) == 0 then
                    back_wall:set(x,y,tile+2)
                end
                if mid_wall:get(x,y) == 0 then
                    mid_wall:set(x,y,tile+2)
                end
                if front_wall:get(x,y) == 0 then
                    front_wall:set(x,y,tile+2)
                end
            end  
        end
    end
end

function MapManager:_load_static(definition: StaticMapDefinition): MapData
    local map_data: MapData = {}

    local map_fetch = fetch(DATP..definition.file) as MapFetchResult

    map_data.layers = self:as_map(map_fetch)
    
    self:apply_checkerboard(map_data.layers)
    self:apply_default_walls(map_data.layers)

    local metatiles_layer = map_data.layers.metatiles
    map_data.width = metatiles_layer:width()
    map_data.height = metatiles_layer:height()
    map_data.metadata = {
        player_spawners = {},
        enemy_spawners = {},
    }

    for x = 0, metatiles_layer:height()-1 do
        for y = 0,metatiles_layer:width()-1 do
            local tile = metatiles_layer:get(x, y)
            if tile >= BASE_PLAYER_SPAWNER_SPRITE and tile < BASE_ENEMY_SPAWNER_SPRITE then
                local player_spawner_id = tile - BASE_PLAYER_SPAWNER_SPRITE + 1
                map_data.metadata.player_spawners[player_spawner_id] = TilePoint.of(x, y)
            elseif tile >= BASE_ENEMY_SPAWNER_SPRITE and tile < BASE_REINFORCEMENT_SPAWNER_SPRITE then
                local enemy_spawner_id = tile - BASE_ENEMY_SPAWNER_SPRITE + 1
                if map_data.metadata.enemy_spawners[enemy_spawner_id] == nil then
                    map_data.metadata.enemy_spawners[enemy_spawner_id] = {}
                end
                add(map_data.metadata.enemy_spawners[enemy_spawner_id], TilePoint.of(x, y))
            end
        end
    end

    return map_data
end

-- function MapManager:_generate_procedural(definition) end

--- Returns a grid table and metadata table
-- @param map_def: The entry from MAP_DEFINITIONS
-- @return map: The Picotron map data
-- @return meta: table containing { events={} }
function MapManager:load_map(map_id: string): MapData
    local definition = MAP_DEFINITIONS[map_id]
    assert(definition ~= nil)

    local map_data: MapData
    if definition is StaticMapDefinition then
        map_data = self:_load_static(definition)
    -- elseif definition is ProceduralMapDefinition then

    end

    return map_data
end

return MapManager
