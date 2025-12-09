
require("src/systems/service")
require("src/systems/event_bus")
require("src/battle/battle_state")
require("src/battle/tactics/tactics_engine")

global record BattleObjectiveService
    is TransientGameService
    where self.id == 'battle_objective_service'

    battle_state: BattleState
    tactics_engine: TacticsEngine
end

function BattleObjectiveService:init(service_manager: ServiceManager, services: { ServiceId: GameService })
end

function BattleObjectiveService.new(): BattleObjectiveService 
    local self: BattleObjectiveService = setmetatable({
        id = 'battle_objective_service',
        dependencies = {
            "tactics_engine",
            "battle_state",
        }
    }, { __index = BattleObjectiveService })

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

    local players = self.battle_state:get_units(unit_is_player)
    local enemies = self.battle_state:get_units(unit_is_enemy)

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