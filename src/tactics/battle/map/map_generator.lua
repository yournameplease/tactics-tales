---@brief
--- A utility for loading and preparing battle maps from map files.
--- It processes map layers and generates the final BattleMap object.

local point = require("src.tactics.util.point")
local battle_map = require("src.tactics.battle.battle_map")

local map_generator = {}

local BASE_METATILE = 0x400

---@class MapFetchResultEntry
---@field name string Layer name (e.g. "floor", "metatiles").
---@field bmp userdata Sprite data for this layer.

--- Convert a raw pt.fetch result into a MapLayers table.
---@param map_fetch MapFetchResultEntry[] Raw fetch result array.
---@return MapLayers
local function as_map(map_fetch)
    local by_layer = {}
    for _, v in ipairs(map_fetch) do
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

--- Apply a checkerboard tile offset to even-sum ground tiles that have flag 0x40.
---@param map_layers MapLayers
local function apply_checkerboard(map_layers)
    local ground = map_layers.terrain.ground
    for x = 0, ground:height() - 1 do
        for y = 0, ground:width() - 1 do
            local tile = ground:get(x, y)
            if x + y & 1 == 0 and pt.fget(tile) & 0x40 == 0x40 then
                ground:set(x, y, tile + 1)
            end
        end
    end
end

--- Fill empty back_wall and front_wall slots on ground tiles that have flag 0x80.
---@param map_layers MapLayers
local function apply_default_walls(map_layers)
    local ground = map_layers.terrain.ground
    local back_wall = map_layers.terrain.back_wall
    local front_wall = map_layers.terrain.front_wall
    for x = 0, ground:height() - 1 do
        for y = 0, ground:width() - 1 do
            local tile = ground:get(x, y)
            if pt.fget(tile) & 0x80 == 0x80 then
                if back_wall:get(x, y) == 0 then
                    back_wall:set(x, y, tile + 2)
                end
                if front_wall:get(x, y) == 0 then
                    front_wall:set(x, y, tile + 2)
                end
            end
        end
    end
end

--- Load a static map from disk, apply post-processing, and build the BattleMap.
---@param definition StaticMapDefinition
---@param tile_labels table<string, integer[]> Metatile indices grouped by label name.
---@return BattleMap
local function load_static(definition, tile_labels)
    local map_fetch = pt.fetch(DATP .. definition.file)

    local layers = as_map(map_fetch)

    apply_checkerboard(layers)
    apply_default_walls(layers)

    local metatiles_layer = layers.metatiles
    local labels_by_metatile = {}
    for label, metatiles in pairs(tile_labels) do
        for _, metatile in ipairs(metatiles) do
            if labels_by_metatile[metatile] == nil then
                labels_by_metatile[metatile] = {}
            end
            table.insert(labels_by_metatile[metatile], label)
        end
    end

    local labels = {}
    for x = 0, metatiles_layer:height() - 1 do
        for y = 0, metatiles_layer:width() - 1 do
            local metatile = metatiles_layer:get(x, y) - BASE_METATILE
            if labels_by_metatile[metatile] ~= nil then
                local p = point.of(x, y)
                for _, label in ipairs(labels_by_metatile[metatile]) do
                    if labels[label] == nil then
                        labels[label] = {}
                    end
                    table.insert(labels[label], p)
                end
            end
        end
    end

    local map = battle_map.new(metatiles_layer:width(), metatiles_layer:height(), labels)
    map.layers = layers
    map.metadata = {
        player_spawners = {},
        enemy_spawners = {},
    }

    return map
end

--- Load and return a BattleMap from the given map definition and label mapping.
---@param definition MapDefinition Map definition specifying type and source file.
---@param labels table<string, integer[]> Metatile indices grouped by label name.
---@return BattleMap
function map_generator.load_map(definition, labels)
    if definition.type == "static" then
        return load_static(definition, labels)
    else
        error("unknown map type")
    end
end

return map_generator
