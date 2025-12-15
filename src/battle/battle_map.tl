require("src/types")
require("src/util")
require("src/battle/tactics/battle_unit")

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
    front_wall: Userdata
    mid_wall: Userdata
    back_wall: Userdata
    ground: Userdata
end

global record MapMetadata
    player_spawners: { integer: TilePoint }
    enemy_spawners: { integer: { TilePoint } }
end

global record BattleMap    
    width: integer
    height: integer
    
    units_by_id: { integer: BattleUnit }
    units_by_x_y: Array2D<BattleUnit>
    
    layers: MapLayers 
    metadata: MapMetadata
end

function BattleMap.new(width: integer, height: integer): BattleMap
    local self: BattleMap = setmetatable({
        units_by_id = {},
        units_by_x_y = Array2D.new(width, height),
    }, { __index = BattleMap })
    return self
end

-- data access

function BattleMap:get_terrain(tile: TilePoint): TerrainData
    local ground = self.layers.ground
    local back_wall = self.layers.back_wall
    local mid_wall = self.layers.mid_wall
    local front_wall = self.layers.front_wall
    
    local tile_sprite = ground:get(tile.x,tile.y)
    if tile_sprite == 0 then return nil end
    
    local flags = pt.fget_all(tile_sprite)
    local terrain = (flags & 0xD) >> 1
    local terrain_data = TERRAIN_DATA[terrain]

    local solid = flags & 0x1 == 0x1
    if back_wall then
        local back_wall_sprite = back_wall:get(tile.x,tile.y)
        if (pt.fget_all(back_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end
    if mid_wall then
        local mid_wall_sprite = mid_wall:get(tile.x,tile.y)
        if (pt.fget_all(mid_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end
    if front_wall then
        local front_wall_sprite = front_wall:get(tile.x,tile.y)
        if (pt.fget_all(front_wall_sprite) & 0x1) == 0x1 then
            solid = true
        end
    end
    
    return {
        solid = solid,
        movement_cost = terrain_data.movement_cost,
        dodge = terrain_data.dodge,
    }
end

function BattleMap:get_unit_by_id(id: integer): BattleUnit
    return self.units_by_id[id]
end

function BattleMap:get_at_tile(tile: TilePoint): BattleUnit
    return self.units_by_x_y:get_point(tile)
end

function BattleMap:spawn_unit(unit: BattleUnit, tile: TilePoint)
    if self:get_at_tile(tile) ~= nil then
        error("Tried to spawn unit in an occupied tile! (".. tile.x .. "," .. tile.y .. ")")
    end

    local id = unit.id
    self.units_by_id[id] = unit
    self.units_by_x_y:set_point(tile, unit)
end

function BattleMap:tile_is_legal_destination(unit: BattleUnit, tile: TilePoint): boolean
    local unit_id_at_destination = self.units_by_x_y:get_point(tile)
    return (unit_id_at_destination == nil
            or unit_id_at_destination.id == unit.id)
end

function BattleMap:move_unit(unit: BattleUnit, tile: TilePoint)
    assert(self:tile_is_legal_destination(unit, tile))

    self.units_by_x_y:set_point(unit.tile, nil)
    self.units_by_x_y:set_point(tile, unit)
    unit.tile = tile
end

function BattleMap:kill_unit(unit: BattleUnit)
    self.units_by_x_y:set_point(unit.tile, nil)
    self.units_by_id[unit.id] = nil
    unit:die()
end


-- queries


function BattleMap:tile_has_distance_from_tile(t1: TilePoint, t2: TilePoint, min_distance: integer, max_distance: integer): boolean
    max_distance = max_distance or min_distance
    local distance = taxicab_distance(t1, t2)
    return distance >= min_distance and distance <= max_distance
end

function BattleMap:get_targets_in_range(unit_id: integer, tile: TilePoint): { BattleUnit }
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

function BattleMap:get_units(filter: function(BattleUnit): boolean): { BattleUnit }
    local units: { BattleUnit } = {}
    for _,unit in pairs(self.units_by_id) do
        if filter(unit) then
            pt.add(units, unit)
        end
    end
    return units
end

function BattleMap:get_all_units(): { BattleUnit }
    return self:get_units(fn_true)
end
