---@brief
--- Defines the BattleUnit, which represents a character on the battlefield.
--- It holds transient data like HP, position, and action status,
--- linking to the persistent Character data.

local maps = require("src.tactics.util.maps")

---@class BattleUnit : DrawableCharacterInstance
---@field id UnitId
---@field tile Point Grid position on the battlefield.
---@field hp_current integer Current remaining hit points.
---@field side Side Which team this unit belongs to.
---@field movement_side string Side used for movement rules (defaults to side).
---@field has_acted boolean True when the unit has already taken an action this turn.
---@field character Character The underlying persistent character.
---@field unit_ai UnitAI AI behaviour descriptor for this unit.
---@field tags table<string, boolean> Set of string tags associated with this unit.
---@field marked boolean True when the unit is currently marked.
local BattleUnit = {}
BattleUnit.__index = BattleUnit

local battle_unit = {
    BattleUnit = BattleUnit,
}

--- Return true if this unit has the given tag.
---@param tag string
---@return boolean
function BattleUnit:has_tag(tag)
    return self.tags[tag]
end

--- Return true if this unit is currently marked.
---@return boolean
function BattleUnit:is_marked()
    return self.marked
end

--- Return true if this unit is on the player's side.
---@return boolean
function BattleUnit:is_player()
    return self.side == "player"
end

--- Return true if this unit is neutral.
---@return boolean
function BattleUnit:is_neutral()
    return self.side == "neutral"
end

--- Return true if this unit is on the enemy side.
---@return boolean
function BattleUnit:is_enemy()
    return self.side == "enemy"
end

--- Return true if the underlying character is still alive.
---@return boolean
function BattleUnit:is_alive()
    return not self.character.dead
end

--- Return true if the underlying character is dead.
---@return boolean
function BattleUnit:is_dead()
    return self.character.dead
end

--- Spawn a new BattleUnit from a persistent character record.
---@param permanent_unit Character The persistent character this unit represents.
---@param tile Point Starting grid position.
---@param tags string[] Additional tags to apply to this unit.
---@param side Side Which team this unit belongs to.
---@param movement_side string Side used for movement rules; defaults to `side`.
---@param facing Facing Initial facing direction.
---@param ai UnitAI AI behaviour descriptor.
---@return BattleUnit
function battle_unit.spawn_unit(permanent_unit, tile, tags, side, movement_side, facing, ai)
    local instance = {
        id = permanent_unit.id,
        tile = tile,
        hp_current = permanent_unit.stats.hp_max,
        has_acted = false,
        character = permanent_unit,
        tags = maps.merge(
            maps.set(tags),
            permanent_unit.tags
        ),
        side = side,
        movement_side = movement_side or side,
        facing = facing,
        marked = false,
        unit_ai = ai,
        sprites = {},
    }

    setmetatable(instance, {
        __index = BattleUnit,
        __tostring = function(u)
            local tags_str = nil
            for tag, _ in pairs(u.tags) do
                if tags_str == nil then
                    tags_str = tag
                else
                    tags_str = tags_str .. ", " .. tag
                end
            end
            return "Unit " .. u.id
                .. ": " .. u.character.name
                .. " - " .. u.side
                .. " (" .. tags_str .. ")"
        end
    })

    return instance
end

--- Return a predicate function that checks whether a unit has the given tag.
---@param tag string Tag to test for.
---@return fun(unit: BattleUnit): boolean
function battle_unit.has_tag(tag)
    return function(unit)
        return unit:has_tag(tag)
    end
end

--- Reduce this unit's HP by `amount`, clamped to [0, hp_max].
---@param amount integer Damage to apply.
function BattleUnit:take_damage(amount)
    local new_hp = math.max(0, math.min(self.hp_current - amount, self.character.stats.hp_max))
    self.hp_current = new_hp
end

--- Kill this unit, marking the underlying character as dead.
function BattleUnit:die()
    log.debug("Killing " .. tostring(self))
    self.character.dead = true
end

return battle_unit
