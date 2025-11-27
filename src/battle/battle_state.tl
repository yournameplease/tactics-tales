
local BattleState = {}
BattleState.__index = BattleState

function BattleState.new(width, height)
    local self = setmetatable({}, BattleState)
    self.units_by_id = {}
    -- map of [x][y] for each entity in the map
    self.units_by_x_y = {}
    for i=0,width-1 do
        self.units_by_x_y[i] = {}
    end
    return self
end

function BattleState:spawn_unit(unit, x, y)
    if self.units_by_x_y[x][y] ~= nil then
        error("Tried to spawn unit in an occupied tile! (".. x .. "," .. y .. ")")
    end

    local id = unit.id
    self.units_by_id[id] = unit
    self.units_by_x_y[x][y] = id
end

function BattleState:tile_is_legal_destination(unit, x, y)
    local unit_id_at_destination = self.units_by_x_y[x][y]
    return (unit_id_at_destination == nil
            or unit_id_at_destination == unit.id)
end

function BattleState:move_unit(unit, x, y)
    assert(self:tile_is_legal_destination(unit, x, y))

    self.units_by_x_y[unit.x][unit.y] = nil
    self.units_by_x_y[x][y] = unit.id
    unit.x = x
    unit.y = y
end

function BattleState:kill_unit(unit)
    self.units_by_x_y[unit.x][unit.y] = nil
    self.units_by_id[unit.id] = nil
    unit:die()
end

-- data access

function BattleState:get_unit_by_id(id)
    return self.units_by_id[id]
end

function BattleState:get_unit_at_coordinates(x, y)
    local unit_id = self.units_by_x_y[x][y]
    if unit_id == nil then return nil end
    return self:get_unit_by_id(unit_id)
end

-- queries

function BattleState:get_targets_in_range(unit_id, x, y)
    local targets = {}
    local attacker = self.units_by_id[unit_id]
    local min_range = attacker.weapon.min_range
    local max_range = attacker.weapon.max_range
    for target in all(self.units_by_id) do
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

function BattleState:get_units(filter)
    filter = filter or fn_true
    local units = {}
    for unit in all(self.units_by_id) do
        if filter(unit) then
            add(units, unit)
        end
    end
    return units
end


return BattleState
