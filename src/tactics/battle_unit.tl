
-- TODO: some of this moves to character/weapon files

global record WeaponInstance
    min_range: integer
    max_range: integer
end

global record BattleUnit
    id: integer
    x: integer
    y: integer
    side: integer
    weapon: WeaponInstance
end

local function access_fallback(table, key)
    if table.source.stats[key] then
        return table.source.stats[key]
    end

    return table.source[key]
end

function BattleUnit.spawn(permanent_unit, x, y, side)
    local instance = {
        x = x,
        y = y,
        side = side,
        hp_current = permanent_unit.stats.hp_max,
        has_acted = false,
        source = permanent_unit
    }

    setmetatable(instance, {
        __index = function(t, k)
            if BattleUnit[k] then return BattleUnit[k] end

            return access_fallback(t, k)
        end
    })

    return instance
end

function BattleUnit:is_alive()
    return self.hp_current > 0
end

function BattleUnit:take_damage(amount)
    local new_hp = mid(0, self.hp_current - amount, self.stats.hp_max)
    self.hp_current = new_hp
end

function BattleUnit:die()
    LOG.info("Unit "..self.id.." is now dead")
end

return BattleUnit
