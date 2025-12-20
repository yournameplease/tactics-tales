require("src/tactics/debug")

require("src/tactics/animation")
require("src/tactics/types")
require("src/tactics/character/object/character")
require("src/tactics/character/items/object/weapon")


local SIDE_PLAYER = 0
local SIDE_ENEMY = 1

global record BattleUnit
    id: integer
    tile: TilePoint
    hp_current: integer
    side: Side
    has_acted: boolean

    animation_data: AnimatedSpriteData
    character: Character

    is_player: function(self): boolean
    is_enemy: function(self): boolean
end

function BattleUnit:is_player(): boolean
    return self.side == SIDE_PLAYER
end

function BattleUnit:is_enemy(): boolean
    return self.side == SIDE_ENEMY
end

-- local function access_fallback(tab, k)
--     if tab.source.stats[k] then
--         return tab.source.stats[k]
--     end

--     return tab.source[k]
-- end

function BattleUnit.spawn(permanent_unit: Character, tile: TilePoint, side: Side): BattleUnit
    local instance: BattleUnit = {
        id = permanent_unit.id,
        tile = tile,
        side = side,
        hp_current = permanent_unit.stats.hp_max,
        has_acted = false,
        character = permanent_unit
    }

    -- setmetatable(instance, {
    --     __index = function(t, k)
    --         if BattleUnit[k] then return BattleUnit[k] end

    --         return access_fallback(t, k)
    --     end
    -- })
    setmetatable(instance, { __index = BattleUnit })

    return instance
end

function BattleUnit:is_alive(): boolean
    return self.hp_current > 0
end

function BattleUnit:take_damage(amount: integer)
    local new_hp = pt.mid(0, self.hp_current - amount, self.character.stats.hp_max)
    self.hp_current = new_hp
end

function BattleUnit:die()
    LOG.info("Unit "..self.id.." is now dead")
end

return BattleUnit
