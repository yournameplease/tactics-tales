---@brief
--- Represents the state of the battlefield, including terrain and unit positions.
--- Provides an API for querying and manipulating the map and the
--- units residing on it.

local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
local point = require("src.tactics.util.point")
local fp = require("src.tactics.util.fp")
local array_2d = require("src.tactics.util.array_2d")
local lists = require("src.tactics.util.lists")

---@alias TerrainLocation "ceiling"|"front_wall"|"mid_wall"|"back_wall"|"ground"

---@alias NewTilesMap table<TerrainLocation, integer>

---@class TerrainData
---@field solid boolean Whether this terrain blocks movement.
---@field movement_cost integer AP cost to move through this tile.
---@field dodge integer Dodge bonus provided by this terrain.

---@class MapLayers
---@field metatiles userdata Metatile layer used for semantic tile labeling.
---@field terrain table<TerrainLocation, userdata> Per-layer terrain sprite data.
---@field decorations userdata[]? Ordered decoration tilelayers (decoration_* prefix).

---@class MapMetadata
---@field player_spawners table<integer, Point> Indexed spawner positions for player units.
---@field enemy_spawners table<integer, Point[]> Indexed spawn groups for enemy units.

---@class SpawnPoint
---@field x integer
---@field y integer
---@field slot string Role designator for this point (defaults to "default").
---@field ai_hint string? Advisory AI behavior for the unit at this point.

---@class SpawnGroup
---@field from string? Edge this group enters from for reinforcement waves.
---@field points SpawnPoint[]

---@class BattleMap
---@field width integer
---@field height integer
---@field units_by_id table<UnitId, BattleUnit> Active units keyed by ID.
---@field units_by_x_y Array2D<BattleUnit> Active units keyed by tile position.
---@field dead_units BattleUnit[] Units that have been killed this battle.
---@field interactions_by_unit_id table<UnitId, table<ScriptId, UnitInteractionHook>>
---@field interactions_by_x_y Array2D<table<TileDistance, table<ScriptId, TileInteractionHook>>>
---@field tile_labels table<string, Point[]> Points grouped by semantic tile label.
---@field spawn_groups table<string, SpawnGroup> Named spawn groups extracted from Tiled object layers.
---@field layers MapLayers Sprite layers making up the map.
---@field metadata MapMetadata Spawn point and event metadata.
local BattleMap = {}
BattleMap.__index = BattleMap

local battle_map = {
    BattleMap = BattleMap,
}

local TERRAIN_DATA = {
    [0] = { movement_cost = 1, dodge = 0 },
    [1] = { movement_cost = 2, dodge = 0 },
    [2] = { movement_cost = 2, dodge = 0 },
    [3] = { movement_cost = 3, dodge = 0 },
    [4] = { movement_cost = 4, dodge = 0 },
    [5] = { movement_cost = 3, dodge = 0 },
    [6] = { movement_cost = 5, dodge = 0 },
    [7] = { movement_cost = 2, dodge = 0 },
}

--- Create a new empty BattleMap with the given dimensions and tile labels.
---@param width integer
---@param height integer
---@param labels table<string, Point[]> Pre-computed tile labels from metatile data.
---@return BattleMap
function battle_map.new(width, height, labels)
    ---@type BattleMap
    local self = setmetatable({
        units_by_id = {},
        dead_units = {},
        units_by_x_y = array_2d.new(width, height),
        interactions_by_unit_id = {},
        interactions_by_x_y = array_2d.new(width, height),
    }, BattleMap)
    self.tile_labels = labels
    self.width = width
    self.height = height
    return self
end

--- Return true if `tile` is within the map boundaries.
---@param tile Point
---@return boolean
function BattleMap:tile_is_in_map(tile)
    return tile.x >= 0 and tile.x < self.width
        and tile.y >= 0 and tile.y < self.height
end

--- Return a userdata grid produced by calling `func` at each tile position.
---@param ud_type string Picotron userdata type string (e.g. "u8").
---@param func fun(point: Point): integer Called for each tile to produce its value.
---@return userdata
function BattleMap:get_tiles_userdata_by(ud_type, func)
    local ud = userdata(ud_type, self.width, self.height)
    for x = 0, self.width - 1 do
        for y = 0, self.height - 1 do
            ud:set(x, y, func(point.of(x, y)))
        end
    end
    return ud
end

--- Return all tile positions with the given label, or an empty table.
---@param label string
---@return Point[]
function BattleMap:get_tiles_by_label(label)
    if self.tile_labels[label] then
        return self.tile_labels[label]
    else
        return {}
    end
end

--- Return true if `tile` carries the given label.
---@param tile Point
---@param label string
---@return boolean
function BattleMap:tile_has_label(tile, label)
    if self.tile_labels[label] then
        return lists.contains(self.tile_labels[label], tile)
    else
        return false
    end
end

--- Return a 2D boolean array marking every tile that carries the given label.
---@param label string
---@return Array2D<boolean>
function BattleMap:get_tiles_array_by_label(label)
    local points = self:get_tiles_by_label(label)
    local out = array_2d.new(self.width, self.height, false)
    for _, p in ipairs(points) do
        out:set_point(p, true)
    end
    return out
end

--- Return terrain data for `tile`, or nil if the tile has no ground sprite.
---@param tile Point
---@return TerrainData?
function BattleMap:get_terrain(tile)
    local ground = self.layers.terrain.ground
    local back_wall = self.layers.terrain.back_wall
    local mid_wall = self.layers.terrain.mid_wall
    local front_wall = self.layers.terrain.front_wall

    local tile_sprite = ground:get(tile.x, tile.y)
    if tile_sprite == 0 then return nil end

    local flags = fget(tile_sprite)
    local terrain = (flags & 0xD) >> 1
    local terrain_data = TERRAIN_DATA[terrain]

    local solid = flags & 0x1 == 0x1
    if back_wall then
        local back_wall_sprite = back_wall:get(tile.x, tile.y)
        if (fget(back_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end
    if mid_wall then
        local mid_wall_sprite = mid_wall:get(tile.x, tile.y)
        if (fget(mid_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end
    if front_wall then
        local front_wall_sprite = front_wall:get(tile.x, tile.y)
        if (fget(front_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end

    return {
        solid = solid,
        movement_cost = terrain_data.movement_cost,
        dodge = terrain_data.dodge,
    }
end

--- Update terrain sprites for all tiles carrying the given label.
---@param label string
---@param new_terrain NewTilesMap Per-layer replacement sprite index.
function BattleMap:update_terrain(label, new_terrain)
    local tiles = self:get_tiles_by_label(label)
    for _, t in ipairs(tiles) do
        for terrain, new_tile in pairs(new_terrain) do
            self.layers.terrain[terrain]:set(t.x, t.y, new_tile)
        end
    end
end

--- Return the unit with the given ID, or nil.
---@param id integer
---@return BattleUnit?
function BattleMap:get_unit_by_id(id)
    return self.units_by_id[id]
end

--- Return the unit occupying `tile`, or nil.
---@param tile Point
---@return BattleUnit?
function BattleMap:get_at_tile(tile)
    if not self.units_by_x_y:is_point_in_range(tile) then
        return nil
    end
    return self.units_by_x_y:get_point(tile)
end

--- Place `unit` on the map at `tile`. Errors if the tile is already occupied.
---@param unit BattleUnit
---@param tile Point
function BattleMap:spawn_unit(unit, tile)
    assert(unit.id ~= nil)
    if self:get_at_tile(tile) ~= nil then
        error("Tried to spawn unit in an occupied tile! (" .. tile.x .. "," .. tile.y .. ")")
    end
    local id = unit.id
    self.units_by_id[id] = unit
    self.units_by_x_y:set_point(tile, unit)
end

--- Remove the unit with the given ID from the map.
---@param unit_id UnitId
function BattleMap:remove_unit(unit_id)
    local unit = self.units_by_id[unit_id]
    assert(unit.id ~= nil)
    self.units_by_id[unit_id] = nil
    self.units_by_x_y:set_point(unit.tile, nil)
end

--- Return true if `tile` is a valid destination for `unit` (empty or occupied by the unit itself).
---@param unit BattleUnit
---@param tile Point
---@return boolean
function BattleMap:tile_is_legal_destination(unit, tile)
    local unit_at_destination = self.units_by_x_y:get_point(tile)
    return (unit_at_destination == nil
        or unit_at_destination.id == unit.id)
end

--- Move `unit` to `tile`, asserting the destination is legal.
---@param unit BattleUnit
---@param tile Point
function BattleMap:move_unit(unit, tile)
    assert(self:tile_is_legal_destination(unit, tile))
    self.units_by_x_y:set_point(unit.tile, nil)
    self.units_by_x_y:set_point(tile, unit)
    unit.tile = tile
end

--- Swap the units occupying `tile_a` and `tile_b`.
---@param tile_a Point
---@param tile_b Point
function BattleMap:swap_tile_units(tile_a, tile_b)
    assert(self:tile_is_in_map(tile_a))
    assert(self:tile_is_in_map(tile_b))

    local unit_a = self.units_by_x_y:get_point(tile_a)
    local unit_b = self.units_by_x_y:get_point(tile_b)

    if unit_a ~= nil then
        unit_a.tile = tile_b
    end
    if unit_b ~= nil then
        unit_b.tile = tile_a
    end
    self.units_by_x_y:set_point(tile_a, unit_b)
    self.units_by_x_y:set_point(tile_b, unit_a)
end

--- Move `unit` to the dead list and remove it from active play.
---@param unit BattleUnit
function BattleMap:kill_unit(unit)
    table.insert(self.dead_units, unit)
    self.units_by_x_y:set_point(unit.tile, nil)
    self.units_by_id[unit.id] = nil
end

--- Return true if taxicab distance between `t1` and `t2` is within `[min_distance, max_distance]`.
---@param t1 Point
---@param t2 Point
---@param min_distance integer
---@param max_distance? integer
---@return boolean
function BattleMap:tile_has_distance_from_tile(t1, t2, min_distance, max_distance)
    max_distance = max_distance or min_distance
    local distance = point.taxicab_distance(t1, t2)
    return distance >= min_distance and distance <= max_distance
end

---Whether one side can attack the other
---@param side_1 Side
---@param side_2 Side
---@return boolean
function sides_can_fight(side_1, side_2)
    if side_1 == side_2 then
        return false
    end
    if side_1 == "player" and side_2 == "neutral" then
        return false
    end
    if side_2 == "player" and side_1 == "neutral" then
        return false
    end
    return true
end


--- Return all enemy units in weapon range of `unit_id` from `tile`.
---@param unit_id UnitId
---@param tile Point
---@return BattleUnit[]
function BattleMap:get_targets_in_range(unit_id, tile)
    local targets = {}
    local attacker = self.units_by_id[unit_id]
    local targeting = attacker.character:get_weapon_targeting()
    for _, target in pairs(self.units_by_id) do
        if target.id ~= attacker.id then
            if sides_can_fight(attacker.side, target.side)
                and targeting.is_target_valid(
                    tile,
                    target.tile,
                    battle_map
                )
            then
                table.insert(targets, target)
            end
        end
    end
    return targets
end

--- Return all active units matching `filter`.
---@param filter fun(unit: BattleUnit): boolean
---@return BattleUnit[]
function BattleMap:get_units(filter)
    local units = {}
    for _, unit in pairs(self.units_by_id) do
        if filter(unit) then
            table.insert(units, unit)
        end
    end
    return units
end

--- Return all dead units matching `filter`.
---@param filter fun(unit: BattleUnit): boolean
---@return BattleUnit[]
function BattleMap:get_dead_units(filter)
    return lists.filter(filter)(self.dead_units)
end

--- Return all active units.
---@return BattleUnit[]
function BattleMap:get_all_units()
    return self:get_units(fp.fn_true)
end

--- Remove all registered interactions for `script_id` from the map.
---@param script_id ScriptId
function BattleMap:unregister_interaction(script_id)
    self.interactions_by_x_y:foreachpoint(function(_, i)
        for _, interactions in pairs(i) do
            interactions[script_id] = nil
        end
    end)

    for _, interactions in pairs(self.interactions_by_unit_id) do
        interactions[script_id] = nil
    end
end

--- Register a tile interaction triggered when a unit is at or adjacent to `tile`.
---@param tile Point
---@param script_id ScriptId
---@param interaction_text string Prompt shown to the player.
---@param interaction_distance TileDistance
function BattleMap:register_tile_interaction(tile, script_id, interaction_text, interaction_distance)
    log.debug("Registering tile interaction: ", tile, script_id)
    local hook = {
        script_id = script_id,
        interaction_text = interaction_text,
        interaction_distance = interaction_distance,
    }

    local interactions_at_point = self.interactions_by_x_y:get_point(tile)
    if interactions_at_point == nil then
        self.interactions_by_x_y:set_point(tile, {})
        interactions_at_point = self.interactions_by_x_y:get_point(tile)
        assert(interactions_at_point)
    end

    if interactions_at_point[interaction_distance] == nil then
        interactions_at_point[interaction_distance] = {}
    end

    interactions_at_point[interaction_distance][script_id] = hook
end

--- Register a unit interaction triggered when a unit is adjacent to `unit`.
---@param unit BattleUnit
---@param script_id ScriptId
---@param interaction_text string Prompt shown to the player.
function BattleMap:register_unit_interaction(unit, script_id, interaction_text)
    log.debug("Registering unit interaction: ", unit, script_id)
    local hook = {
        script_id = script_id,
        interaction_text = interaction_text,
    }

    if self.interactions_by_unit_id[unit.id] == nil then
        self.interactions_by_unit_id[unit.id] = {}
    end
    self.interactions_by_unit_id[unit.id][script_id] = hook
end

--- Return all interactions available when a unit stands at `tile`.
---@param tile Point
---@return InteractionHook[]
function BattleMap:get_nearby_interactions(tile)
    local adjacent_offsets = {
        point.of(0, -1),
        point.of(-1, 0),
        point.of(1, 0),
        point.of(0, 1),
    }
    local out = {}

    do
        local tile_interactions = self.interactions_by_x_y:get_point(tile)
        if tile_interactions ~= nil and tile_interactions["on"] ~= nil then
            local interactions = tile_interactions["on"]
            for _, i in pairs(interactions) do
                local hook = {
                    script_id = i.script_id,
                    interaction_text = i.interaction_text,
                    target_tile = point,
                }
                table.insert(out, hook)
            end
        end
    end

    for _, offset in ipairs(adjacent_offsets) do
        local p = tile + offset
        if self.interactions_by_x_y:is_point_in_range(p) then
            local tile_interactions = self.interactions_by_x_y:get_point(p)
            if tile_interactions ~= nil and tile_interactions["adjacent"] ~= nil then
                local interactions = tile_interactions["adjacent"]
                for _, i in pairs(interactions) do
                    local hook = {
                        script_id = i.script_id,
                        interaction_text = i.interaction_text,
                        target_tile = p,
                    }
                    table.insert(out, hook)
                end
            end
        end
    end

    for _, offset in ipairs(adjacent_offsets) do
        local p = tile + offset
        local unit = self:get_at_tile(p)
        if unit ~= nil then
            local unit_interactions = self.interactions_by_unit_id[unit.id]
            if unit_interactions ~= nil then
                for _, i in pairs(unit_interactions) do
                    local hook = {
                        script_id = i.script_id,
                        interaction_text = i.interaction_text,
                        target_tile = p,
                        target_unit = unit,
                    }
                    table.insert(out, hook)
                end
            end
        end
    end

    return out
end

--- Return a userdata marking every tile that has an "on" tile interaction.
---@return userdata
function BattleMap:get_tile_highlights()
    local ud = userdata("u8", self.width, self.height)
    for x = 0, self.width - 1 do
        for y = 0, self.height - 1 do
            local interactions = self.interactions_by_x_y:get(x, y)
            if interactions ~= nil and interactions["on"] ~= nil then
                for _, _ in pairs(interactions["on"]) do
                    ud:set(x, y, HIGHLIGHT.IS_INTERACTION)
                    break
                end
            end
        end
    end
    return ud
end

return battle_map
