---@brief
--- A utility for loading and preparing battle maps from map files.
--- It processes map layers and generates the final BattleMap object.

---@alias MapGenerationType "static"|"tiled"|"procgen"

---@class MapDefinition Abstract base for all map definition variants.
---@field type MapGenerationType

---@class StaticMapDefinition : MapDefinition
---@field type "static"
---@field file string Path to the static map file.

---@class TiledMapDefinition : MapDefinition
---@field type "tiled"
---@field file string Path to Tiled .lua export (no extension), relative to mod root.

local point = require("src.tactics.util.point")
local battle_map = require("src.tactics.battle.battle_map")

local map_generator = {}

local BASE_METATILE = 0x400

---@class MapFetchResultEntry
---@field name string Layer name (e.g. "floor", "metatiles").
---@field bmp userdata Sprite data for this layer.

--- Convert a raw fetch result into a MapLayers table.
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
            if x + y & 1 == 0 and fget(tile) & 0x40 == 0x40 then
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
            if fget(tile) & 0x80 == 0x80 then
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

--- Strip the extension from a filename, returning only the stem.
---@param filename string
---@return string
local function file_stem(filename)
    return (filename:match("^(.+)%..+$") or filename)
end

--- Build a userdata grid from a Tiled layer data array.
---@param layer_data integer[] Flat row-major tile-ID array (1-indexed).
---@param map_w integer Map width in tiles.
---@param map_h integer Map height in tiles.
---@param tile_to_sprite fun(id: integer): integer
---@return userdata
local function tiled_layer_to_userdata(layer_data, map_w, map_h, tile_to_sprite)
    local bmp = userdata("i16", map_w, map_h)
    for row = 0, map_h - 1 do
        for col = 0, map_w - 1 do
            local tile_id = tile_to_sprite(layer_data[row * map_w + col + 1])
            bmp:set(col, row, tile_id)
        end
    end
    return bmp
end

--- Extract rectangle objects from Tiled object layers into a rect_zones table.
--- Only layers containing at least one rectangle object are included.
---@param tiled_data table
---@return table<string, RectZone>
local function extract_rect_zones(tiled_data)
    local tile_w = tiled_data.tilewidth
    local tile_h = tiled_data.tileheight
    local zones = {}
    for _, layer in ipairs(tiled_data.layers) do
        if layer.type == "objectgroup" then
            local layer_zones = {}
            for _, obj in ipairs(layer.objects or {}) do
                if obj.shape == "rectangle" then
                    table.insert(layer_zones, {
                        x = math.floor(obj.x / tile_w),
                        y = math.floor(obj.y / tile_h),
                        w = math.floor(obj.width / tile_w),
                        h = math.floor(obj.height / tile_h),
                    })
                end
            end
            if #layer_zones > 0 then
                zones[layer.name] = layer_zones[1]
            end
        end
    end
    return zones
end

--- Extract object layers from a Tiled map into a spawn_groups table.
--- Per-layer properties supply defaults; per-object properties override them.
---@param tiled_data table
---@return table<string, SpawnGroup>
local function extract_spawn_groups(tiled_data)
    local tile_w = tiled_data.tilewidth
    local tile_h = tiled_data.tileheight
    local groups = {}
    for _, layer in ipairs(tiled_data.layers) do
        if layer.type == "objectgroup" then
            local layer_props   = layer.properties or {}
            local group         = {
                from   = layer_props["from"] or nil,
                points = {},
            }
            local layer_ai_hint = layer_props["ai_hint"]
            local layer_slot    = layer_props["slot"]
            for _, obj in ipairs(layer.objects or {}) do
                if obj.shape == "point" then
                    local obj_props = obj.properties or {}
                    local pt = {
                        x    = math.floor(obj.x / tile_w),
                        y    = math.floor(obj.y / tile_h),
                        slot = obj_props["slot"] or layer_slot or "default",
                    }
                    local ai_hint = obj_props["ai_hint"] or layer_ai_hint
                    if ai_hint then pt.ai_hint = ai_hint end
                    table.insert(group.points, pt)
                end
            end
            groups[layer.name] = group
        end
    end
    return groups
end

--- Load a Tiled .lua map export, convert tile IDs via gfx_registry, and build the BattleMap.
---@param definition TiledMapDefinition
---@param tile_labels table<string, integer[]>
---@param gfx_registry table<string, integer>
---@return BattleMap
local function load_tiled(definition, tile_labels, gfx_registry)
    log.debug("load_tiled: file='" .. tostring(definition.file) .. "'")
    local tiled_data = include(definition.file .. ".lua")

    if tiled_data == nil then
        log.error("load_tiled: include returned nil for '" .. tostring(definition.file) .. ".lua'")
        error("tiled map file not found: " .. tostring(definition.file))
    end

    local map_w = tiled_data.width
    local map_h = tiled_data.height
    log.debug("load_tiled: map size " .. map_w .. "x" .. map_h)

    do
        local keys = {}
        for k, v in pairs(gfx_registry) do table.insert(keys, k .. "=" .. tostring(v)) end
        log.debug("load_tiled: gfx_registry { " .. table.concat(keys, ", ") .. " }")
    end

    -- Build tileset ranges; keyed by firstgid for direct lookup.
    local ranges = {}
    for _, ts in ipairs(tiled_data.tilesets) do
        local stem = file_stem(ts.filename)
        local base = gfx_registry[stem] or 0
        log.debug("load_tiled: tileset '" ..
            tostring(ts.filename) .. "' stem='" .. stem .. "' firstgid=" .. tostring(ts.firstgid) .. " base=" ..
            tostring(base))
        table.insert(ranges, { firstgid = ts.firstgid, base = base })
    end

    local function tile_to_sprite(tile_id)
        if tile_id == 0 then return 0 end
        local best_firstgid = 0
        local best_base = 0
        for _, r in ipairs(ranges) do
            if tile_id >= r.firstgid and r.firstgid > best_firstgid then
                best_firstgid = r.firstgid
                best_base = r.base
            end
        end
        return best_base + (tile_id - best_firstgid)
    end

    -- Index tile layers by name (skip non-tilelayer entries).
    local tile_layers = {}
    local layer_names = {}
    for _, layer in ipairs(tiled_data.layers) do
        if layer.type == "tilelayer" then
            tile_layers[layer.name] = layer.data
            table.insert(layer_names, layer.name)
        end
    end
    log.debug("load_tiled: tile layers found: " .. table.concat(layer_names, ", "))

    assert(tile_layers["ground"], "tiled map missing required 'ground' layer: " .. tostring(definition.file))

    local function opt_layer(name)
        return tile_layers[name] and tiled_layer_to_userdata(tile_layers[name], map_w, map_h, tile_to_sprite) or nil
    end

    local layers = {
        metatiles = opt_layer("metatiles"),
        terrain = {
            ground     = tiled_layer_to_userdata(tile_layers["ground"], map_w, map_h, tile_to_sprite),
            front_wall = opt_layer("front_walls"),
            mid_wall   = opt_layer("mid_walls"),
            back_wall  = opt_layer("back_walls"),
            ceiling    = opt_layer("ceiling"),
        }
    }

    -- Build tile labels from the metatiles layer when present.
    local labels = {}
    if layers.metatiles then
        local labels_by_metatile = {}
        for label, metatiles in pairs(tile_labels) do
            for _, metatile in ipairs(metatiles) do
                if labels_by_metatile[metatile] == nil then
                    labels_by_metatile[metatile] = {}
                end
                table.insert(labels_by_metatile[metatile], label)
            end
        end

        local ml = layers.metatiles
        for x = 0, ml:height() - 1 do
            for y = 0, ml:width() - 1 do
                local metatile = ml:get(x, y) - BASE_METATILE
                if labels_by_metatile[metatile] ~= nil then
                    local p = point.of(x, y)
                    for _, label in ipairs(labels_by_metatile[metatile]) do
                        if labels[label] == nil then labels[label] = {} end
                        table.insert(labels[label], p)
                    end
                end
            end
        end
    end

    local decorations = {}
    for _, layer in ipairs(tiled_data.layers) do
        if layer.type == "tilelayer" and layer.name:match("^decoration_") then
            table.insert(decorations, tiled_layer_to_userdata(layer.data, map_w, map_h, tile_to_sprite))
        end
    end
    layers.decorations = decorations

    local map = battle_map.new(map_w, map_h, labels)
    map.layers = layers
    map.spawn_groups = extract_spawn_groups(tiled_data)
    map.rect_zones = extract_rect_zones(tiled_data)
    map.metadata = { player_spawners = {}, enemy_spawners = {} }

    return map
end

--- Load a static map from disk, apply post-processing, and build the BattleMap.
---@param definition StaticMapDefinition
---@param tile_labels table<string, integer[]> Metatile indices grouped by label name.
---@return BattleMap
local function load_static(definition, tile_labels)
    local map_fetch = fetch(DATP .. definition.file)

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

    local map = battle_map.new(metatiles_layer:width() --[[@as integer]], metatiles_layer:height() --[[@as integer]],
        labels)
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
---@param gfx_registry table<string, integer>|nil Required for type="tiled"; maps gfx stem to base sprite index.
---@return BattleMap
function map_generator.load_map(definition, labels, gfx_registry)
    if definition.type == "static" then
        return load_static(definition --[[@as StaticMapDefinition]], labels)
    elseif definition.type == "tiled" then
        return load_tiled(definition --[[@as TiledMapDefinition]], labels, gfx_registry or {})
    else
        error("unknown map type")
    end
end

return map_generator
