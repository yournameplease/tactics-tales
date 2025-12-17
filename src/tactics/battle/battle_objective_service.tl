
require("src/systems/service")
require("src/systems/event_bus")
require("src/battle/battle_map")
require("src/battle/battle_context")
require("src/battle/tactics/tactics_engine")

global record BattleObjectiveService
    ctx: BattleContext
end

function BattleObjectiveService.new(ctx: BattleContext): BattleObjectiveService 
    local self: BattleObjectiveService = setmetatable({
        ctx = ctx
    }, { __index = BattleObjectiveService })

    return self
end

global record BattleFinishState
    finished: boolean
    command: GameEvent
end

-- legacy function, doesn't support different end conditions
function BattleObjectiveService:check_for_end(): BattleFinishState
    if self.ctx.tactics_engine:is_blocked() then
        return { finished = false }
    end

    local players = self.ctx.battle_map:get_units(unit_is_player)
    local enemies = self.ctx.battle_map:get_units(unit_is_enemy)

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
