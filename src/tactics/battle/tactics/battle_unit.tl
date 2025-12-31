require("src/tactics/debug")
require("src/tactics/character/animation_data")
require("src/tactics/animation")
local point = require("src/tactics/util/point")
local Point = point.Point
require("src/tactics/character/object/character")
require("src/tactics/character/items/object/weapon")
local unit_ai = require("src/tactics/battle/unit/unit_ai")
local maps = require("src/tactics/util/maps")


global record BattleUnit
    is DrawableCharacterInstance

    id: integer
    tile: Point
    hp_current: integer
    side: Side
    has_acted: boolean
    
    character: Character

    unit_ai: unit_ai.UnitAI
    labels: maps.Set<string>

    is_player: function(self): boolean
    is_neutral: function(self): boolean
    is_enemy: function(self): boolean
end

local battle_unit = {
    BattleUnit = BattleUnit,
    Side = Side,
}

function BattleUnit:is_player(): boolean
    return self.side == "player"
end

function BattleUnit:is_neutral(): boolean
    return self.side == "neutral"
end

function BattleUnit:is_enemy(): boolean
    return self.side == "enemy"
end

-- local function access_fallback(tab, k)
--     if tab.source.stats[k] then
--         return tab.source.stats[k]
--     end

--     return tab.source[k]
-- end

function battle_unit.spawn_unit(permanent_unit: Character, tile: Point, labels: {string}, side: Side, ai: unit_ai.UnitAI): BattleUnit
    local instance: BattleUnit = {
        id = permanent_unit.id,
        tile = tile,
        hp_current = permanent_unit.stats.hp_max,
        has_acted = false,
        character = permanent_unit,
        labels = maps.set(labels),
        side = side,
        unit_ai = ai,
        sprites = {},
    }

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

return battle_unit
