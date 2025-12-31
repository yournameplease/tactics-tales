local point = require("src/tactics/util/point")
local Point = point.Point
require("src/tactics/data/maps")
local battle_map = require("src/tactics/battle/battle_map")
local BattleMap = battle_map.BattleMap
local MAP_DEFINITIONS = require("src/tactics/data/maps")
local map_types = require("src/tactics/battle/map/types")
local battle_definition_types = require("src/tactics/battle/definition/types")


local map_generator = {
    
}

local record __MapFetchResultEntry
    bmp: Userdata
end

local type MapFetchResult = { __MapFetchResultEntry }



local BASE_METATILE= 0x400

local METATILES_LAYER = 1
local FRONT_WALL_LAYER = 2
local MID_WALL_LAYER = 3
local BACK_WALL_LAYER = 4
local GROUND_LAYER = 5

local function as_map(map: MapFetchResult): battle_map.MapLayers
    return {
        metatiles = map[METATILES_LAYER].bmp,
        terrain = {
            front_wall = map[FRONT_WALL_LAYER].bmp,
            mid_wall = map[MID_WALL_LAYER].bmp,
            back_wall = map[BACK_WALL_LAYER].bmp,
            ground = map[GROUND_LAYER].bmp,
        }
    }
end

local function apply_checkerboard(map_layers: battle_map.MapLayers)
    local ground = map_layers.terrain.ground
    for x = 0,ground:height()-1 do
        for y = 0,ground:width()-1 do
            local tile = ground:get(x, y)
            if x+y & 1 == 0 and pt.fget(tile) & 0x40 == 0x40 then
                ground:set(x, y, tile+1)
            end  
        end
    end
end

local function apply_default_walls(map_layers: battle_map.MapLayers)
    local ground = map_layers.terrain.ground
    local back_wall = map_layers.terrain.back_wall
    -- mid wall makes ui look ugly
    -- local mid_wall = map_layers.terrain.mid_wall
    local front_wall = map_layers.terrain.front_wall
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

local function load_static(definition: map_types.StaticMapDefinition, tile_labels: {battle_definition_types.TileLabel: {integer}}): BattleMap
    local map_fetch = pt.fetch(DATP..definition.file) as MapFetchResult

    local layers = as_map(map_fetch)
    
    apply_checkerboard(layers)
    apply_default_walls(layers)

    local metatiles_layer = layers.metatiles
    local labels_by_metatile: {integer: {battle_definition_types.TileLabel}} = {}
    for label,metatiles in pairs(tile_labels) do
        for _,metatile in ipairs(metatiles) do
            if labels_by_metatile[metatile] == nil then
                labels_by_metatile[metatile] = {}
            end
            pt.add(labels_by_metatile[metatile], label)
        end        
    end
    
    local labels: {battle_definition_types.TileLabel: {Point}} = {}
    for x = 0, metatiles_layer:height()-1 do
        for y = 0,metatiles_layer:width()-1 do
            local metatile = metatiles_layer:get(x, y) - BASE_METATILE
            if labels_by_metatile[metatile] ~= nil then
                local p = point.of(x, y)
                for _,label in ipairs(labels_by_metatile[metatile]) do
                    if labels[label] == nil then
                        labels[label] = {}
                    end
                    pt.add(labels[label], p)
                end
            end
        end
    end
    
    local map: BattleMap = battle_map.new(metatiles_layer:width(), metatiles_layer:height(), labels)
    map.layers = layers
    map.metadata = {
        player_spawners = {},
        enemy_spawners = {},
    }


    return map
end

-- function MapGenerator:_generate_procedural(definition) end

--- Returns a grid table and metadata table
-- @param map_def: The entry from MAP_DEFINITIONS
-- @return map: The Picotron map data
-- @return meta: table containing { events={} }
function map_generator.load_map(map_id: string, labels: {battle_definition_types.TileLabel: {integer}}): BattleMap
    local definition = MAP_DEFINITIONS[map_id]
    assert(definition ~= nil)

    local map: BattleMap
    if definition is map_types.StaticMapDefinition then
        map = load_static(definition, labels)
    -- elseif definition is ProceduralMapDefinition then

    else
        error("unknown map type")
    end

    return map
end

return map_generator
