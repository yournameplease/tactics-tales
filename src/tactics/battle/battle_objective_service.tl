local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local event_bus = require("src/tactics/systems/event_bus")
local battle_objective_definition = require("src/tactics/battle/definition/objective")
local battle_objective = require("src/tactics/battle/objective")
local lists = require("src/tactics/util/lists")

local interface BattleObjectiveService
    check_objectives: function(self, turn_number: integer): BattleFinishState
    get_objective_text: function(self, turn_number: integer): {string}
end

local record BattleFinishState
    finished: boolean
    command: event_bus.GameEvent
end

local battle_objective_service = {
    BattleObjectiveService = BattleObjectiveService,
    BattleFinishState = BattleFinishState
}

local record BattleObjectiveServiceImpl
    is BattleObjectiveService
    battle_map: BattleMap
    turn_limit: integer
    victory_conditions: { battle_objective.VictoryCondition }
    failure_conditions: { battle_objective.FailureCondition }
end

function battle_objective_service.new(
    map: BattleMap,
    turn_limit: integer,
    victory_conditions: { battle_objective_definition.VictoryCondition },
    failure_conditions: { battle_objective_definition.FailureCondition }
): BattleObjectiveService 
    victory_conditions = victory_conditions or {}
    failure_conditions = failure_conditions or {}

    local self: BattleObjectiveServiceImpl = setmetatable({
    }, { __index = BattleObjectiveServiceImpl })

    self.battle_map = map
    self.turn_limit = turn_limit
    self.victory_conditions = lists.map(battle_objective_definition.to_victory_condition)(victory_conditions)
    self.failure_conditions = lists.map(battle_objective_definition.to_failure_condition)(failure_conditions)
    
    return self
end

--- Checks if current state satisfies Victory/Failure conditions
-- Called by TurnManager at end of actions
function BattleObjectiveServiceImpl:check_objectives(turn_number: integer): BattleFinishState
    -- returns "WIN", "LOSS", or nil (continue)
    local turn_limit_exceeded = self.turn_limit and turn_number > self.turn_limit

    for _,f in ipairs(self.failure_conditions) do
        if f:check(self.battle_map, turn_limit_exceeded) then
            return { finished = true, command = "BATTLE_END_DEFEAT" }
        end
    end
    for _,v in ipairs(self.victory_conditions) do
        if v:check(self.battle_map, turn_limit_exceeded) then
            return { finished = true, command = "BATTLE_END_VICTORY" }
        end
    end

    return { finished = false }    
end

function BattleObjectiveServiceImpl:get_objective_text(turn_number: integer): {string}
    local out: {string} = {}

    if self.turn_limit then
        pt.add(out, "Turn "..turn_number.."/"..self.turn_limit) 
    end
    for _,v in ipairs(self.victory_conditions) do
        if v.text then
            pt.add(out, v.text)
        end
    end
    for _,f in ipairs(self.failure_conditions) do
        if f.text then
            pt.add(out, f.text)
        end
    end
    
    return out
end

return battle_objective_service
