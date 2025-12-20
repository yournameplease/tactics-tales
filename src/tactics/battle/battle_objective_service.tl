
require("src/tactics/systems/service")
require("src/tactics/systems/event_bus")
require("src/tactics/battle/battle_map")
require("src/tactics/battle/battle_context")
require("src/tactics/battle/tactics/tactics_engine")

global record BattleObjectiveService
    battle_map: BattleMap
    tactics_engine: TacticsEngine
end

function BattleObjectiveService.new(
    battle_map: BattleMap,
    tactics_engine: TacticsEngine
): BattleObjectiveService 
    local self: BattleObjectiveService = setmetatable({
    }, { __index = BattleObjectiveService })

    self.battle_map = battle_map
    self.tactics_engine = tactics_engine
    
    return self
end

global record BattleFinishState
    finished: boolean
    command: GameEvent
end

-- legacy function, doesn't support different end conditions
function BattleObjectiveService:check_for_end(): BattleFinishState
    if self.tactics_engine:is_blocked() then
        return { finished = false }
    end

    local players = self.battle_map:get_units(unit_is_player)
    local enemies = self.battle_map:get_units(unit_is_enemy)

    if (#players == 0) then
        return { finished = true, command = "BATTLE_END_VICTORY" }
    elseif (#enemies == 0) then
        return { finished = true, command = "BATTLE_END_DEFEAT" }
    else
        return { finished = false }
    end
end

--- Checks if current state satisfies Victory/Failure conditions
-- Called by TurnManager at end of actions
function BattleObjectiveService:check_objectives(): BattleFinishState
    -- returns "WIN", "LOSS", or nil (continue)
    return self:check_for_end()
end

return BattleObjectiveService
