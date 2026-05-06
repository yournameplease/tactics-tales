---@brief
--- Cache of valid tile bitfields for each unit, plus the aggregated
--- marked-enemy-unit overlay.  Extracted from TacticsEngine so it can be
--- tested with a real BattleMap without instantiating the full engine.

local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
local point = require("src.tactics.util.point")
local pathfinding = require("src.tactics.battle.pathfinding")

---@class TileReachabilityCache
---@field battle_map BattleMap
---@field valid_tiles_by_unit table<integer, userdata> Cached tile maps keyed by unit ID.
---@field marked_unit_tiles userdata Bitfield map of tiles threatened by marked enemy units.
---@field marked_unit_revision integer Incremented whenever the marked-unit set changes.
local TileReachabilityCache = {}
TileReachabilityCache.__index = TileReachabilityCache

local tile_reachability_cache = {
    TileReachabilityCache = TileReachabilityCache,
}

---@param battle_map BattleMap
---@return TileReachabilityCache
function tile_reachability_cache.new(battle_map)
    ---@type TileReachabilityCache
    local self = setmetatable({}, TileReachabilityCache)
    self.battle_map = battle_map
    self.valid_tiles_by_unit = {}
    self.marked_unit_tiles = userdata("u8", battle_map.width, battle_map.height)
    self.marked_unit_revision = 0
    return self
end

--- Return a u8 userdata with CAN_ATTACK|IS_VALID bits set for tiles reachable
--- by `unit`'s weapon from `tile`.
---@param unit BattleUnit
---@param tile Point
---@return userdata
function TileReachabilityCache:_tiles_with_distance_from_unit_attacks(unit, tile)
    local targeting = unit.character:get_weapon_targeting()
    local tiles_in_distance = targeting.get_selection_tiles(tile, self.battle_map)
    local tiles = userdata("u8", self.battle_map.width, self.battle_map.height)

    for _, t in ipairs(tiles_in_distance) do
        local tile_unit = self.battle_map:get_at_tile(t)
        local current = tiles:get(t.x, t.y)
        -- TODO: extract a "can_attack" function
        if unit:is_player() then
            if tile_unit ~= nil then
                if tile_unit.side == "enemy" then
                    tiles:set(t.x, t.y, current | HIGHLIGHT.CAN_ATTACK | HIGHLIGHT.IS_VALID)
                elseif tile_unit.side == "neutral" then
                    local interactions = self.battle_map.interactions_by_unit_id[tile_unit.id]
                    if interactions and next(interactions) then
                        tiles:set(t.x, t.y, current | HIGHLIGHT.IS_VALID)
                    end
                end
            end
            -- neutral units: interaction destination is handled via get_nearby_interactions
        else
            tiles:set(t.x, t.y, current | HIGHLIGHT.CAN_ATTACK | HIGHLIGHT.IS_VALID)
        end
    end

    return tiles
end

--- Return a u8 userdata whose bits signify reachable (0x1), valid selection
--- (0x2), and attack range (0x4) for `unit`.
---@param unit BattleUnit
---@return userdata
function TileReachabilityCache:_tiles_in_movement_and_attack_range_for_unit(unit)
    local movement = unit.character.stats.movement
    if unit.unit_ai ~= nil and unit.unit_ai.move == "zero" then
        movement = 0
    end

    local reachable_tiles = pathfinding.find_reachable_tiles(
        self.battle_map,
        unit.tile.x,
        unit.tile.y,
        unit.movement_side,
        movement
    )

    local tiles = userdata("u8", self.battle_map.width, self.battle_map.height)

    reachable_tiles:foreach(function(x, y, reachable)
        if reachable then
            local p = point.of(x, y)
            local tile = tiles:get(x, y)
            tile = tile | HIGHLIGHT.IS_VALID
            tile = tile | HIGHLIGHT.IS_REACHABLE

            local has_attack = #self.battle_map:get_targets_in_range(unit.id, p) > 0
            local has_interaction = #self.battle_map:get_nearby_interactions(p) > 0
            if has_attack or has_interaction then
                tile = tile | HIGHLIGHT.IS_INTERACTION_DESTINATION
            end

            tiles:set(x, y, tile)

            local tiles_in_attack_range = self:_tiles_with_distance_from_unit_attacks(unit, p)
            tiles = tiles | tiles_in_attack_range
        end
    end)

    return tiles
end

--- Return the cached valid-tile map for `unit`, computing it on first access.
---@param unit BattleUnit
---@return userdata
function TileReachabilityCache:get_valid_tiles_for_unit(unit)
    if self.valid_tiles_by_unit[unit.id] == nil then
        self.valid_tiles_by_unit[unit.id] = self:_tiles_in_movement_and_attack_range_for_unit(unit)
    end
    return self.valid_tiles_by_unit[unit.id]
end

--- OR this unit's attack-range tiles into `marked_unit_tiles`.
---@param unit BattleUnit
function TileReachabilityCache:add_unit_to_marked_tiles(unit)
    self.marked_unit_tiles = self.marked_unit_tiles
        | ((self:get_valid_tiles_for_unit(unit) & HIGHLIGHT.CAN_ATTACK) << 1)
end

--- Recompute `marked_unit_tiles` from all currently marked enemy units.
function TileReachabilityCache:recompute_marked_unit_tiles()
    local marked_units = self.battle_map:get_units(function(u) return u.marked end)
    self.marked_unit_tiles = self.marked_unit_tiles - self.marked_unit_tiles
    for _, unit in ipairs(marked_units) do
        self.marked_unit_tiles = self.marked_unit_tiles
            | ((self:get_valid_tiles_for_unit(unit) & HIGHLIGHT.CAN_ATTACK) << 1)
    end
end

--- Evict the cached tile map for `unit`.
---@param unit BattleUnit
function TileReachabilityCache:invalidate_tiles_for_unit(unit)
    if unit == nil or unit.id == nil then
        log.warn("attempt to invalidate tiles for a nil unit.")
        return
    end

    self.valid_tiles_by_unit[unit.id] = nil
    if unit.is_marked then
        self:recompute_marked_unit_tiles()
    end
end

--- Evict cached tile maps for all units whose movement range covers point `p`.
---@param p Point
function TileReachabilityCache:invalidate_tiles_for_point(p)
    for id, _ in pairs(self.valid_tiles_by_unit) do
        local unit = self.battle_map:get_unit_by_id(id)
        if unit == nil then
            -- unit died
            self.valid_tiles_by_unit[id] = nil
            self:recompute_marked_unit_tiles()
        elseif point.taxicab_distance(unit.tile, p) <= unit.character.stats.movement then
            self:invalidate_tiles_for_unit(unit)
        end
    end
end

return tile_reachability_cache
