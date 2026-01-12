require("src/tactics/debug")
require("src/tactics/character/animation_data")
require("src/tactics/animation")
local point = require("src/tactics/util/point")
local Point = point.Point
local character = require("src/tactics/character/object/character")
require("src/tactics/character/items/object/weapon")
local unit_ai = require("src/tactics/battle/unit/unit_ai")
local maps = require("src/tactics/util/maps")


local record BattleUnit
    is character.DrawableCharacterInstance

    id: integer
    tile: Point
    hp_current: integer
    side: character.Side
    has_acted: boolean
    
    character: character.Character

    unit_ai: unit_ai.UnitAI
    labels: maps.Set<string>

    valid_tiles: Userdata
    marked: boolean

    is_marked: function(self): boolean
    is_player: function(self): boolean
    is_neutral: function(self): boolean
    is_enemy: function(self): boolean
end

local battle_unit = {
    BattleUnit = BattleUnit,
    Side = character.Side,
}

function BattleUnit:has_tag(tag: string): boolean
    return self.labels[tag]
end

function BattleUnit:is_marked(): boolean
    return self.marked
end

function BattleUnit:is_player(): boolean
    return self.side == "player"
end

function BattleUnit:is_neutral(): boolean
    return self.side == "neutral"
end

function BattleUnit:is_enemy(): boolean
    return self.side == "enemy"
end

function battle_unit.spawn_unit(
    permanent_unit: character.Character,
    tile: Point,
    labels: {string},
    side: character.Side,
    facing: character.Facing,
    ai: unit_ai.UnitAI
): BattleUnit
    local instance: BattleUnit = {
        id = permanent_unit.id,
        tile = tile,
        hp_current = permanent_unit.stats.hp_max,
        has_acted = false,
        character = permanent_unit,
        labels = maps.set(labels),
        side = side,
        facing = facing,
        valid_tiles = nil,
        marked = false,
        unit_ai = ai,
        sprites = {},
    }

    setmetatable(instance, { __index = BattleUnit })

    return instance
end

function battle_unit.has_tag(tag: string): function(BattleUnit): boolean
    return function(unit: BattleUnit): boolean
        return unit:has_tag(tag)
    end
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
