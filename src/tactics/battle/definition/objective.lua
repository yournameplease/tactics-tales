---@brief
--- Defines the data structures for battle objectives.
--- These definitions are used in battle data files and are converted
--- into active objective instances by a factory function.

local battle_objectives = require("src.tactics.battle.objective")

---@alias VictoryConditionType "rout"|"defeat_tagged"|"survive"|"escape"

---@class VictoryConditionDef Abstract base for all victory condition definitions loaded from mod data.
---@field type VictoryConditionType
---@field text? string Display text shown to the player describing the objective.
local VictoryCondition = {}

---@class RoutDef : VictoryConditionDef Victory by defeating all enemy units.
---@field type "rout"
local Rout = {}

---@class DefeatTaggedDef : VictoryConditionDef Victory by defeating all units bearing a specific tag.
---@field type "defeat_tagged"
---@field tag string Tag identifying the units that must all be defeated.
local DefeatTagged = {}

---@class SurviveDef : VictoryConditionDef Victory by surviving until the turn limit is reached.
---@field type "survive"
local Survive = {}

---@class EscapeDef : VictoryConditionDef Victory when all player units have left the map.
---@field type "escape"
local Escape = {}

---@alias FailureConditionType "tagged_unit_dies"|"all_players_die"|"turn_limit"

---@class FailureConditionDef Abstract base for all failure condition definitions loaded from mod data.
---@field type FailureConditionType
---@field text? string Display text shown to the player describing the failure condition.
local FailureCondition = {}

---@class TaggedPlayerDiesDef : FailureConditionDef Failure if any player unit with the given tag is killed.
---@field type "tagged_unit_dies"
---@field tag string Tag identifying the player unit(s) that must survive.
local TaggedPlayerDies = {}

---@class AllPlayersDieDef : FailureConditionDef Failure if all player units are defeated.
---@field type "all_players_die"
local AllPlayersDie = {}

---@class TurnLimitDef : FailureConditionDef Failure if the battle exceeds its turn limit.
---@field type "turn_limit"
local TurnLimit = {}

local battle_objective_definition = {
    VictoryCondition = VictoryCondition,
    FailureCondition = FailureCondition,
}

--- Convert a victory condition definition into an active VictoryCondition instance.
---@param def VictoryConditionDef
---@return VictoryCondition
function battle_objective_definition.to_victory_condition(def)
    if def.type == "rout" then
        return battle_objectives.rout(def.text)
    elseif def.type == "defeat_tagged" then
        ---@cast def DefeatTaggedDef
        return battle_objectives.defeat_tagged(def.text, def.tag)
    elseif def.type == "survive" then
        return battle_objectives.survive(def.text)
    elseif def.type == "escape" then
        return battle_objectives.escape(def.text)
    else
        unexpected(def.type)
        error(def.type)
    end
end

--- Convert a failure condition definition into an active FailureCondition instance.
---@param def FailureConditionDef
---@return FailureCondition
function battle_objective_definition.to_failure_condition(def)
    if def.type == "all_players_die" then
        return battle_objectives.all_players_die(def.text)
    elseif def.type == "tagged_unit_dies" then
        ---@cast def TaggedPlayerDiesDef
        return battle_objectives.tagged_player_dies(def.text, def.tag)
    elseif def.type == "turn_limit" then
        return battle_objectives.turn_limit(def.text)
    else
        unexpected(def.type)
        error(def.type)
    end
end

return battle_objective_definition
