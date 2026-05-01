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
---@field current_turn integer Current turn number, kept in sync by set_turn().
---@field objective_text string[] Cached display text; recomputed by set_turn() each turn.
---@field package victory_conditions VictoryCondition[] Active victory conditions to evaluate each turn.
---@field package failure_conditions FailureCondition[] Active failure conditions to evaluate each turn.
local BattleObjectiveService = {}
BattleObjectiveService.__index = BattleObjectiveService

local battle_objective_service = {}

---@param self BattleObjectiveService
---@return string[]
local function compute_objective_text(self)
    local out = {}
    for _, v in ipairs(self.victory_conditions) do
        if v.text then table.insert(out, v.text) end
    end
    for _, f in ipairs(self.failure_conditions) do
        if f.text then table.insert(out, f.text) end
    end
    for i = 2, #out do
        out[i] = "or " .. out[i]
    end
    if self.turn_limit then
        table.insert(out, 1, "Turn " .. self.current_turn .. "/" .. self.turn_limit)
    end
    return out
end

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
    self.current_turn = 1
    self.victory_conditions = lists.map(battle_objective_definition.to_victory_condition)(victory_conditions)
    self.failure_conditions = lists.map(battle_objective_definition.to_failure_condition)(failure_conditions)
    self.objective_text = compute_objective_text(self)

    return self
end

--- Advance to a new turn, updating the cached objective text.
---@param turn integer
function BattleObjectiveService:set_turn(turn)
    self.current_turn = turn
    self.objective_text = compute_objective_text(self)
end

--- Check victory and failure conditions against the current map state.
--- Failure conditions are evaluated before victory conditions; a simultaneous loss takes priority.
---@return BattleFinishState
function BattleObjectiveService:check_objectives()
    local turn_limit_exceeded = self.turn_limit ~= nil and self.current_turn > self.turn_limit

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

return battle_objective_service
