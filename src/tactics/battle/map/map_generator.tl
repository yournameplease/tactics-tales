---@brief
--- A utility for loading and preparing battle maps from map files.
--- It processes map layers and generates the final BattleMap object.

local point = require("src.tactics.util.point")
local Point = point.Point
local battle_map = require("src.tactics.battle.battle_map")
local map_types = require("src.tactics.battle.map.types")
local battle_definition_types = require("src.tactics.battle.definition.types")


local map_generator = {
    
}

local record __MapFetchResultEntry
    name: string
    bmp: Userdata
end

local type MapFetchResult = { __MapFetchResultEntry }

local BASE_METATILE= 0x400

local function as_map(map: MapFetchResult): battle_map.MapLayers
    local by_layer: {string: __MapFetchResultEntry} = {}
    for _,v in ipairs(map) do
        by_layer[v.name] = v
    end

    return {
        metatiles = by_layer["metatiles"].bmp,
        terrain = {
            ceiling = by_layer["ceiling"] and by_layer["ceiling"].bmp or nil,
            front_wall = by_layer["front_walls"].bmp,
            mid_wall = by_layer["mid_walls"].bmp,
            back_wall = by_layer["back_walls"].bmp,
            ground = by_layer["floor"].bmp,
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

local function load_static(
    definition: map_types.StaticMapDefinition,
    tile_labels: {battle_definition_types.TileLabel: {integer}}
): battle_map.BattleMap
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
    
    local map: battle_map.BattleMap = battle_map.new(metatiles_layer:width(), metatiles_layer:height(), labels)
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
function map_generator.load_map(
    definition: map_types.MapDefinition,
    labels: {battle_definition_types.TileLabel: {integer}}
): battle_map.BattleMap
    local map: battle_map.BattleMap
    if definition is map_types.StaticMapDefinition then
        map = load_static(definition, labels)
    -- elseif definition is ProceduralMapDefinition then

    else
        error("unknown map type")
    end

    return map
end

return map_generator
