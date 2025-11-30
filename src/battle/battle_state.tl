require("src/types")
require("src/util")
require("src/battle/tactics/battle_unit")

global record BattleState
    units_by_id: { integer: BattleUnit }
    units_by_x_y: Array2D<BattleUnit>
end

function BattleState.new(width: integer, height: integer): BattleState
    local self: BattleState = setmetatable({}, { __index = BattleState })
    self.units_by_id = {}
    -- map of [x][y] for each entity in the map
    self.units_by_x_y = Array2D.new(width, height)
    return self
end


-- data access

function BattleState:get_unit_by_id(id: integer): BattleUnit
    return self.units_by_id[id]
end

function BattleState:get_at_tile(tile: TilePoint): BattleUnit
    return self.units_by_x_y:get_point(tile)
end

function BattleState:spawn_unit(unit: BattleUnit, tile: TilePoint)
    if self:get_at_tile(tile) ~= nil then
        error("Tried to spawn unit in an occupied tile! (".. tile.x .. "," .. tile.y .. ")")
    end

    local id = unit.id
    self.units_by_id[id] = unit
    self.units_by_x_y:set_point(tile, unit)
end

function BattleState:tile_is_legal_destination(unit: BattleUnit, tile: TilePoint): boolean
    local unit_id_at_destination = self.units_by_x_y:get_point(tile)
    return (unit_id_at_destination == nil
            or unit_id_at_destination.id == unit.id)
end

function BattleState:move_unit(unit: BattleUnit, tile: TilePoint)
    assert(self:tile_is_legal_destination(unit, tile))

    self.units_by_x_y:set_point(unit.tile, nil)
    self.units_by_x_y:set_point(tile, unit)
    unit.tile = tile
end

function BattleState:kill_unit(unit: BattleUnit)
    self.units_by_x_y:set_point(unit.tile, nil)
    self.units_by_id[unit.id] = nil
    unit:die()
end


-- queries


function BattleState:tile_has_distance_from_tile(t1: TilePoint, t2: TilePoint, min_distance: integer, max_distance: integer): boolean
    max_distance = max_distance or min_distance
    local distance = taxicab_distance(t1, t2)
    return distance >= min_distance and distance <= max_distance
end

function BattleState:get_targets_in_range(unit_id: integer, tile: TilePoint): { BattleUnit }
    local targets: { BattleUnit } = {}
    local attacker = self.units_by_id[unit_id]
    local min_range = attacker.character.weapon.min_range
    local max_range = attacker.character.weapon.max_range
    for _,target in pairs(self.units_by_id) do
        if target.id ~= attacker.id then
            if target.side ~= attacker.side
                    and self:tile_has_distance_from_tile(
                    tile,
                    target.tile,
                    min_range, max_range
            ) then
                add(targets, target)
            end
        end
    end
    return targets
end

function BattleState:get_units(filter: function(BattleUnit): boolean): { BattleUnit }
    local units: { BattleUnit } = {}
    for _,unit in pairs(self.units_by_id) do
        if filter(unit) then
            add(units, unit)
        end
    end
    return units
end

function BattleState:get_all_units(): { BattleUnit }
    return self:get_units(fn_true)
end


return BattleState
