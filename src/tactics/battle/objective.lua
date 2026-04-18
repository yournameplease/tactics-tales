---@brief
--- Implements the logic for battle objectives.
--- Contains concrete victory and failure conditions that can be checked
--- against the current battle state.

local BattleUnit = require("src.tactics.battle.tactics.battle_unit").BattleUnit

---@class VictoryCondition Abstract base for all active (runtime) victory condition instances.
---@field text? string Display text describing the objective.
---@field check fun(self: VictoryCondition, battle_map: table, turn_limit_exceeded: boolean): boolean
local VictoryCondition = {}

---@class Rout : VictoryCondition Victory by defeating all enemy units.
local Rout = {}
Rout.__index = Rout

--- Return true when no enemy units remain on the map.
---@param battle_map table BattleMap
---@param _turn_limit_exceeded boolean
---@return boolean
function Rout:check(battle_map, _turn_limit_exceeded)
    local enemies = battle_map:get_units(BattleUnit.is_enemy)
    return #enemies == 0
end

---@class DefeatTaggedCondition : VictoryCondition Victory by defeating all enemies bearing a specific tag.
---@field tag string Tag identifying the enemies that must all be defeated.
local DefeatTagged = {}
DefeatTagged.__index = DefeatTagged

--- Return true when no enemy units with the required tag remain on the map.
---@param battle_map table BattleMap
---@param _turn_limit_exceeded boolean
---@return boolean
function DefeatTagged:check(battle_map, _turn_limit_exceeded)
    local enemies = battle_map:get_units(function(unit)
        return unit:is_enemy() and unit.tags[self.tag]
    end)
    return #enemies == 0
end

---@class Survive : VictoryCondition Victory by surviving until the turn limit is reached.
local Survive = {}
Survive.__index = Survive

--- Return true when the turn limit has been exceeded (i.e. the player survived long enough).
---@param _battle_map table BattleMap
---@param turn_limit_exceeded boolean
---@return boolean
function Survive:check(_battle_map, turn_limit_exceeded)
    return turn_limit_exceeded
end

---@class Escape : VictoryCondition Victory when all player units have left the map.
local Escape = {}
Escape.__index = Escape

--- Return true when no player units remain on the map.
---@param battle_map table BattleMap
---@param _turn_limit_exceeded boolean
---@return boolean
function Escape:check(battle_map, _turn_limit_exceeded)
    local players = battle_map:get_units(BattleUnit.is_player)
    return #players == 0
end

---@class FailureCondition Abstract base for all active (runtime) failure condition instances.
---@field text? string Display text describing the failure condition.
---@field check fun(self: FailureCondition, battle_map: table, turn_limit_exceeded: boolean): boolean
local FailureCondition = {}

---@class AllPlayersDie : FailureCondition Failure if all player units are defeated.
local AllPlayersDie = {}
AllPlayersDie.__index = AllPlayersDie

--- Return true when no player units remain on the map.
---@param battle_map table BattleMap
---@param _turn_limit_exceeded boolean
---@return boolean
function AllPlayersDie:check(battle_map, _turn_limit_exceeded)
    local players = battle_map:get_units(BattleUnit.is_player)
    return #players == 0
end

---@class TaggedPlayerDiesCondition : FailureCondition Failure if any player unit with the given tag is killed.
---@field tag string Tag identifying the player unit(s) that must survive.
local TaggedPlayerDies = {}
TaggedPlayerDies.__index = TaggedPlayerDies

--- Return true when at least one dead player unit bears the required tag.
---@param battle_map table BattleMap
---@param _turn_limit_exceeded boolean
---@return boolean
function TaggedPlayerDies:check(battle_map, _turn_limit_exceeded)
    -- todo: this checks that all tagged players are dead
    -- move to a script if we need to check any one dies
    local players = battle_map:get_dead_units(function(unit)
        return unit:is_player() and unit.tags[self.tag]
    end)
    return #players > 0
end

---@class TurnLimitCondition : FailureCondition Failure if the battle exceeds its turn limit.
local TurnLimit = {}
TurnLimit.__index = TurnLimit

--- Return true when the turn limit has been exceeded.
---@param _battle_map table BattleMap
---@param turn_limit_exceeded boolean
---@return boolean
function TurnLimit:check(_battle_map, turn_limit_exceeded)
    return turn_limit_exceeded
end

local battle_objectives = {
    VictoryCondition = VictoryCondition,
    FailureCondition = FailureCondition,
}

--- Create a Rout victory condition: win when all enemies are defeated.
---@param text string? Display text for the objective.
---@return VictoryCondition
function battle_objectives.rout(text)
    ---@type Rout
    local self = setmetatable({ text = text }, { __index = Rout })
    return self
end

--- Create a DefeatTagged victory condition: win when all enemies with the given tag are defeated.
---@param text string? Display text for the objective.
---@param tag string Tag identifying the enemies that must be defeated.
---@return VictoryCondition
function battle_objectives.defeat_tagged(text, tag)
    ---@type DefeatTaggedCondition
    local self = setmetatable({ text = text, tag = tag }, { __index = DefeatTagged })
    return self
end

--- Create a Survive victory condition: win when the turn limit is reached.
---@param text string? Display text for the objective.
---@return VictoryCondition
function battle_objectives.survive(text)
    ---@type Survive
    local self = setmetatable({ text = text }, { __index = Survive })
    return self
end

--- Create an Escape victory condition: win when all player units have left the map.
---@param text string? Display text for the objective.
---@return VictoryCondition
function battle_objectives.escape(text)
    ---@type Escape
    local self = setmetatable({ text = text }, { __index = Escape })
    return self
end

--- Create an AllPlayersDie failure condition: lose when all player units are defeated.
---@param text string? Display text for the failure condition.
---@return FailureCondition
function battle_objectives.all_players_die(text)
    ---@type AllPlayersDie
    local self = setmetatable({ text = text }, { __index = AllPlayersDie })
    return self
end

--- Create a TaggedPlayerDies failure condition: lose when any player unit with the given tag is killed.
---@param text string? Display text for the failure condition.
---@param tag string Tag identifying the player unit(s) that must survive.
---@return FailureCondition
function battle_objectives.tagged_player_dies(text, tag)
    ---@type TaggedPlayerDiesCondition
    local self = setmetatable({ text = text, tag = tag }, { __index = TaggedPlayerDies })
    return self
end

--- Create a TurnLimit failure condition: lose when the turn limit is exceeded.
---@param text string? Display text for the failure condition.
---@return FailureCondition
function battle_objectives.turn_limit(text)
    ---@type TurnLimitCondition
    local self = setmetatable({ text = text }, { __index = TurnLimit })
    return self
end

return battle_objectives
