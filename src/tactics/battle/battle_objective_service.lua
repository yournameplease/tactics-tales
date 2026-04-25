---@brief
--- A service that manages and checks battle objectives.
--- It holds the victory and failure conditions for the current battle and
--- determines when the battle should end.

local battle_objective_definition = require("src.tactics.battle.definition.objective")
local lists = require("src.tactics.util.lists")

---@class BattleFinishState
---@field finished boolean Whether the battle has ended.
---@field result? BattleEndResult Game event to emit on finish; nil when battle continues.

---@class BattleObjectiveService Abstract interface for checking and displaying battle objectives.
---@field package battle_map table BattleMap used to inspect unit positions and deaths.
---@field package turn_limit integer? Maximum number of turns before the turn-limit condition triggers.
---@field package victory_conditions VictoryCondition[] Active victory conditions to evaluate each turn.
---@field package failure_conditions FailureCondition[] Active failure conditions to evaluate each turn.
local BattleObjectiveService = {}
BattleObjectiveService.__index = BattleObjectiveService

local battle_objective_service = {}

--- Create a new BattleObjectiveService with the given map, turn limit, and objective definitions.
---@param map table BattleMap — the current battle map used to inspect unit positions and deaths.
---@param turn_limit integer? Maximum turns; nil means no turn limit.
---@param victory_conditions VictoryConditionDef[]? Definitions to convert into active conditions.
---@param failure_conditions FailureConditionDef[]? Definitions to convert into active conditions.
---@return BattleObjectiveService
function battle_objective_service.new(map, turn_limit, victory_conditions, failure_conditions)
    victory_conditions = victory_conditions or {}
    failure_conditions = failure_conditions or {}

    ---@type BattleObjectiveService
    local self = setmetatable({}, { __index = BattleObjectiveService })

    self.battle_map = map
    self.turn_limit = turn_limit
    self.victory_conditions = lists.map(battle_objective_definition.to_victory_condition)(victory_conditions)
    self.failure_conditions = lists.map(battle_objective_definition.to_failure_condition)(failure_conditions)

    return self
end

--- Check victory and failure conditions against the current map state.
--- Failure conditions are evaluated before victory conditions; a simultaneous loss takes priority.
---@param turn_number integer The current turn number.
---@return BattleFinishState
function BattleObjectiveService:check_objectives(turn_number)
    local turn_limit_exceeded = self.turn_limit ~= nil and turn_number > self.turn_limit

    for _, f in ipairs(self.failure_conditions) do
        if f:check(self.battle_map, turn_limit_exceeded) then
            return { finished = true, result = "DEFEAT" }
        end
    end
    for _, v in ipairs(self.victory_conditions) do
        if v:check(self.battle_map, turn_limit_exceeded) then
            return { finished = true, result = "VICTORY" }
        end
    end

    return { finished = false }
end

--- Build the list of objective text strings for display in the UI.
--- Turn counter is inserted at position 1 when a turn limit is set; entries after the first are prefixed with "or ".
---@param turn_number integer The current turn number, used to format the turn counter.
---@return string[]
function BattleObjectiveService:get_objective_text(turn_number)
    local out = {}

    for _, v in ipairs(self.victory_conditions) do
        if v.text then
            table.insert(out, v.text)
        end
    end
    for _, f in ipairs(self.failure_conditions) do
        if f.text then
            table.insert(out, f.text)
        end
    end

    for i = 2, #out do
        out[i] = "or " .. out[i]
    end

    if self.turn_limit then
        table.insert(out, 1, "Turn " .. turn_number .. "/" .. self.turn_limit)
    end
    return out
end

return battle_objective_service
