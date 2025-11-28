local MAP_DEFINITIONS = require("src/map/map_data")

global record MapManager

end

local record __MapFetchResultEntry
    bmp: Userdata
end

global record SpawnPoint
    x: integer
    y: integer
end

global record MapMetadata
    player_spawners: { integer: SpawnPoint }
    enemy_spawners: { integer: { SpawnPoint } }
end

global record MapData
    width: integer
    height: integer
    userdata: { __MapFetchResultEntry }
    metadata: MapMetadata
end

local BASE_PLAYER_SPAWNER_SPRITE = 0x408
local BASE_ENEMY_SPAWNER_SPRITE = 0x410
local BASE_REINFORCEMENT_SPAWNER_SPRITE = 0x418

local METATILES_LAYER = 1
local GROUND_LAYER = 3
-- map_data
--

--- Returns a grid table and metadata table
-- @param map_def: The entry from MAP_DEFINITIONS
-- @return map: The Picotron map data
-- @return meta: table containing { events={} }
function MapManager:load_map(map_id: string): MapData
    local definition = MAP_DEFINITIONS[map_id]
    assert(definition ~= nil)

    local map_data: MapData
    if definition.type == "static" then
        map_data = self:_load_static(definition)
    elseif definition.type == "procedural" then

    end

    return map_data
end

function MapManager:_load_static(definition: StaticMapDefinition): MapData
    local map_data = {}

    map_data.userdata = fetch(definition.file) as { __MapFetchResultEntry }

    local metatiles_layer = map_data.userdata[METATILES_LAYER].bmp
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
                map_data.metadata.player_spawners[player_spawner_id] = {x = x, y = y}
            elseif tile >= BASE_ENEMY_SPAWNER_SPRITE and tile < BASE_REINFORCEMENT_SPAWNER_SPRITE then
                local enemy_spawner_id = tile - BASE_ENEMY_SPAWNER_SPRITE + 1
                if map_data.metadata.enemy_spawners[enemy_spawner_id] == nil then
                    map_data.metadata.enemy_spawners[enemy_spawner_id] = {}
                end
                add(map_data.metadata.enemy_spawners[enemy_spawner_id], {x = x, y = y})
            end
        end
    end

    return map_data
end

function MapManager:_generate_procedural(definition) end

return MapManager
