require("src/util")
require("src/tactics/battle_unit")

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

function BattleState:spawn_unit(unit: BattleUnit, x: integer, y: integer)
    if self.units_by_x_y:get(x, y) ~= nil then
        error("Tried to spawn unit in an occupied tile! (".. x .. "," .. y .. ")")
    end

    local id = unit.id
    self.units_by_id[id] = unit
    self.units_by_x_y:set(x, y, unit)
end

function BattleState:tile_is_legal_destination(unit: BattleUnit, x: integer, y: integer): boolean
    local unit_id_at_destination = self.units_by_x_y:get(x, y)
    return (unit_id_at_destination == nil
            or unit_id_at_destination.id == unit.id)
end

function BattleState:move_unit(unit: BattleUnit, x: integer, y: integer)
    assert(self:tile_is_legal_destination(unit, x, y))

    self.units_by_x_y:set(unit.x, unit.y, nil)
    self.units_by_x_y:set(x, y, unit)
    unit.x = x
    unit.y = y
end

function BattleState:kill_unit(unit: BattleUnit)
    self.units_by_x_y:set(unit.x, unit.y, nil)
    self.units_by_id[unit.id] = nil
    unit:die()
end

-- data access

function BattleState:get_unit_by_id(id: integer): BattleUnit
    return self.units_by_id[id]
end

function BattleState:get_unit_at_coordinates(x: integer, y: integer): BattleUnit
    return self.units_by_x_y:get(x, y)
end

-- queries

function BattleState:get_targets_in_range(unit_id: integer, x: integer, y: integer): { BattleUnit }
    local targets: { BattleUnit } = {}
    local attacker = self.units_by_id[unit_id]
    local min_range = attacker.weapon.min_range
    local max_range = attacker.weapon.max_range
    for _,target in pairs(self.units_by_id) do
        if target.id ~= attacker.id then
            if target.side ~= attacker.side
                    and tile_has_distance_from_unit(
                    x, y,
                    target.x, target.y,
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
