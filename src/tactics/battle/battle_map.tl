require("src/tactics/types")
local fp = require("src/tactics/util/fp")
local array_2d = require("src/tactics/util/array_2d")
local battle_unit = require("src/tactics/battle/tactics/battle_unit")
local battle_definition_types = require("src/tactics/battle/definition/types")

global enum TerrainLocation
	"front_wall"
	"mid_wall"
	"back_wall"
	"ground"
end

global type NewTilesMap = {TerrainLocation: integer}

global record TerrainData
    solid: boolean
    movement_cost: integer
    dodge: integer
end

local TERRAIN_DATA: { integer: TerrainData } = {
    [0] = {
        movement_cost = 1,
        dodge = 0
    },
    [1] = {
        movement_cost = 2,
        dodge = 0
    },
    [2] = {
        movement_cost = 2,
        dodge = 0
    },
    [3] = {
        movement_cost = 3,
        dodge = 0
    },
    [4] = {
        movement_cost = 4,
        dodge = 0
    },
    [5] = {
        movement_cost = 3,
        dodge = 0
    },
    [6] = {
        movement_cost = 5,
        dodge = 0
    },
    [7] = {
        movement_cost = 2,
        dodge = 0
    }
}

global record MapLayers
    metatiles: Userdata
    -- should be total
    terrain: {TerrainLocation: Userdata}
end

global record MapMetadata
    player_spawners: { integer: Point }
    enemy_spawners: { integer: { Point } }
end

global record BattleMap    
    width: integer
    height: integer
    
    units_by_id: { integer: battle_unit.BattleUnit }
    units_by_x_y: array_2d.Array2D<battle_unit.BattleUnit>

    tile_labels: {battle_definition_types.TileLabel: {Point}}
    
    layers: MapLayers 
    metadata: MapMetadata
end

local battle_map = {
    BattleMap = BattleMap,
    TerrainLocation = TerrainLocation,
    NewTilesMap = NewTilesMap,
}

function BattleMap.new(width: integer, height: integer, labels: { string: {Point} }): BattleMap
    local self: BattleMap = setmetatable({
        units_by_id = {},
        units_by_x_y = array_2d.new(width, height),
    }, { __index = BattleMap })
    self.tile_labels = labels
    self.width = width
    self.height = height
    return self
end

-- terrain
function BattleMap:get_tiles_by_label(label: battle_definition_types.TileLabel): {Point}
    if self.tile_labels[label] then
        return self.tile_labels[label]
    else
        return {}
    end
end

function BattleMap:get_terrain(tile: Point): TerrainData
    local ground = self.layers.terrain.ground
    local back_wall = self.layers.terrain.back_wall
    local mid_wall = self.layers.terrain.mid_wall
    local front_wall = self.layers.terrain.front_wall
    
    local tile_sprite = ground:get(tile.x,tile.y)
    if tile_sprite == 0 then return nil end
    
    local flags = pt.fget(tile_sprite)
    local terrain = (flags & 0xD) >> 1
    local terrain_data = TERRAIN_DATA[terrain]

    local solid = flags & 0x1 == 0x1
    if back_wall then
        local back_wall_sprite = back_wall:get(tile.x,tile.y)
        if (pt.fget(back_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end
    if mid_wall then
        local mid_wall_sprite = mid_wall:get(tile.x,tile.y)
        if (pt.fget(mid_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end
    if front_wall then
        local front_wall_sprite = front_wall:get(tile.x,tile.y)
        if (pt.fget(front_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end
    
    return {
        solid = solid,
        movement_cost = terrain_data.movement_cost,
        dodge = terrain_data.dodge,
    }
end

function BattleMap:update_terrain(label: string, new_terrain: NewTilesMap)
    local tiles = self:get_tiles_by_label(label)
    for _,t in ipairs(tiles) do
        for terrain,new_tile in pairs(new_terrain) do
            self.layers.terrain[terrain]:set(t.x, t.y, new_tile)
        end
    end
end

--- units

function BattleMap:get_unit_by_id(id: integer): battle_unit.BattleUnit
    return self.units_by_id[id]
end

function BattleMap:get_at_tile(tile: Point): battle_unit.BattleUnit
    return self.units_by_x_y:get_point(tile)
end

function BattleMap:spawn_unit(unit: battle_unit.BattleUnit, tile: Point)
    assert(unit.id ~= nil)
    if self:get_at_tile(tile) ~= nil then
        error("Tried to spawn unit in an occupied tile! (".. tile.x .. "," .. tile.y .. ")")
    end

    local id = unit.id
    self.units_by_id[id] = unit
    self.units_by_x_y:set_point(tile, unit)
end

function BattleMap:tile_is_legal_destination(unit: battle_unit.BattleUnit, tile: Point): boolean
    local unit_id_at_destination = self.units_by_x_y:get_point(tile)
    return (unit_id_at_destination == nil
            or unit_id_at_destination.id == unit.id)
end

function BattleMap:move_unit(unit: battle_unit.BattleUnit, tile: Point)
    assert(self:tile_is_legal_destination(unit, tile))

    self.units_by_x_y:set_point(unit.tile, nil)
    self.units_by_x_y:set_point(tile, unit)
    unit.tile = tile
end

function BattleMap:kill_unit(unit: battle_unit.BattleUnit)
    self.units_by_x_y:set_point(unit.tile, nil)
    self.units_by_id[unit.id] = nil
    unit:die()
end


-- queries


function BattleMap:tile_has_distance_from_tile(t1: Point, t2: Point, min_distance: integer, max_distance: integer): boolean
    max_distance = max_distance or min_distance
    local distance = taxicab_distance(t1, t2)
    return distance >= min_distance and distance <= max_distance
end

function BattleMap:get_targets_in_range(unit_id: integer, tile: Point): { battle_unit.BattleUnit }
    local targets: { BattleUnit } = {}
    local attacker = self.units_by_id[unit_id]
    local min_range, max_range = attacker.character:get_weapon_range()
    for _,target in pairs(self.units_by_id) do
        if target.id ~= attacker.id then
            if target.side ~= attacker.side
                    and self:tile_has_distance_from_tile(
                    tile,
                    target.tile,
                    min_range, max_range
            ) then
                pt.add(targets, target)
            end
        end
    end
    return targets
end

function BattleMap:get_units(filter: function(battle_unit.BattleUnit): boolean): { BattleUnit }
    local units: { BattleUnit } = {}
    for _,unit in pairs(self.units_by_id) do
        if filter(unit) then
            pt.add(units, unit)
        end
    end
    return units
end

function BattleMap:get_all_units(): { battle_unit.BattleUnit }
    return self:get_units(fp.fn_true)
end

return battle_map
