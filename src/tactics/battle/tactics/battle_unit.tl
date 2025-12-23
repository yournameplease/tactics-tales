require("src/tactics/debug")

require("src/tactics/animation")
require("src/tactics/types")
require("src/tactics/character/object/character")
require("src/tactics/character/items/object/weapon")
local unit_ai = require("src/tactics/battle/unit/unit_ai")
local maps = require("src/tactics/util/maps")

local SIDE_PLAYER = 0
local SIDE_ENEMY = 1
local SIDE_NEUTRAL = 2

global record BattleUnit
    id: integer
    tile: Point
    hp_current: integer
    side: Side
    has_acted: boolean

    animation_data: AnimatedSpriteData
    character: Character

    unit_ai: unit_ai.UnitAI
    labels: maps.Set<string>

    is_player: function(self): boolean
    is_neutral: function(self): boolean
    is_enemy: function(self): boolean
end

local battle_unit = {
    BattleUnit = BattleUnit
}

function BattleUnit:is_player(): boolean
    return self.side == SIDE_PLAYER
end

function BattleUnit:is_neutral(): boolean
    return self.side == SIDE_NEUTRAL
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

local function spawn_unit(permanent_unit: Character, tile: Point, labels: {string}): BattleUnit
    local instance: BattleUnit = {
        id = permanent_unit.id,
        tile = tile,
        hp_current = permanent_unit.stats.hp_max,
        has_acted = false,
        character = permanent_unit,
        labels = maps.set(labels)
    }

    setmetatable(instance, { __index = BattleUnit })

    return instance
end

function battle_unit.player(permanent_unit: Character, tile: Point, labels: {string}): BattleUnit
    local instance = spawn_unit(permanent_unit, tile, labels)

    instance.side = SIDE_PLAYER

    return instance
end

function battle_unit.npc(permanent_unit: Character, tile: Point, side: Side, ai: unit_ai.UnitAI, labels: {string}): BattleUnit
    local instance = spawn_unit(permanent_unit, tile, labels)

    instance.side = side
    instance.unit_ai = ai

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
