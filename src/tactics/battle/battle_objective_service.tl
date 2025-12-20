
require("src/tactics/systems/service")
require("src/tactics/systems/event_bus")
require("src/tactics/battle/battle_map")

global record BattleObjectiveService
    battle_map: BattleMap
end

function BattleObjectiveService.new(
    battle_map: BattleMap
): BattleObjectiveService 
    local self: BattleObjectiveService = setmetatable({
    }, { __index = BattleObjectiveService })

    self.battle_map = battle_map
    
    return self
end

global record BattleFinishState
    finished: boolean
    command: GameEvent
end

-- legacy function, doesn't support different end conditions
function BattleObjectiveService:check_for_end(): BattleFinishState
    local players = self.battle_map:get_units(function(u: BattleUnit): boolean return u:is_player() end)
    local enemies = self.battle_map:get_units(function(u: BattleUnit): boolean return u:is_enemy() end)

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
