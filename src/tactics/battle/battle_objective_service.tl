local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local event_bus = require("src/tactics/systems/event_bus")
local battle_objective_definition = require("src/tactics/battle/definition/objective")
local battle_objective = require("src/tactics/battle/objective")
local lists = require("src/tactics/util/lists")

local interface BattleObjectiveService
    check_objectives: function(self, turn_number: integer): BattleFinishState
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
    victory_conditions: { battle_objective.VictoryCondition }
    failure_conditions: { battle_objective.FailureCondition }
end

function battle_objective_service.new(
    map: BattleMap,
    victory_conditions: { battle_objective_definition.VictoryCondition },
    failure_conditions: { battle_objective_definition.FailureCondition }
): BattleObjectiveService 
    local self: BattleObjectiveServiceImpl = setmetatable({
    }, { __index = BattleObjectiveServiceImpl })

    self.battle_map = map
    self.victory_conditions = lists.map(battle_objective_definition.to_victory_condition)(victory_conditions)
    self.failure_conditions = lists.map(battle_objective_definition.to_failure_condition)(failure_conditions)
    
    return self
end

--- Checks if current state satisfies Victory/Failure conditions
-- Called by TurnManager at end of actions
function BattleObjectiveServiceImpl:check_objectives(turn_number: integer): BattleFinishState
    -- returns "WIN", "LOSS", or nil (continue)
    for _,f in ipairs(self.failure_conditions) do
        if f:check(self.battle_map, turn_number) then
            return { finished = true, command = "BATTLE_END_DEFEAT" }
        end
    end
    for _,v in ipairs(self.victory_conditions) do
        if v:check(self.battle_map, turn_number) then
            return { finished = true, command = "BATTLE_END_VICTORY" }
        end
    end

    return { finished = false }    
end

return battle_objective_service
