require("src/debug")

require("src/battle/tactics/enemy_ai")
require("src/menu/battle_menu_manager")
require("src/util/data_utils")
require("src/systems/event_bus")
require("src/battle/tactics/tactics_engine")
require("src/systems/service")
require("src/battle/battle_objective_service")
require("src/battle/battle_context")

local enum Phase
    "PLAYER"
    "ENEMY"
end

global record TurnManager
    turn: integer
    phase: Phase

    ctx: BattleContext
end

function TurnManager.new(ctx: BattleContext): TurnManager
    local self: TurnManager = setmetatable({
        ctx = ctx
    }, { __index = TurnManager })

    self.turn = 1
    self.phase = "PLAYER"

    self.event_bus:on("TACTICS_BEGIN_BATTLE", function()
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        self.event_bus:emit("TACTICS_BEGIN_PLAYER_TURN")
    end)

    self.event_bus:on("TACTICS_UNIT_END_ACTION", function()
        if self.phase == "PLAYER" then
            LOG.debug("Setting to player turn menu")
            self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        end        
    end)

    self.event_bus:on("TACTICS_BEGIN_PLAYER_TURN", function()
        LOG.info("Begin player turn!")
        self.phase = "PLAYER"
        self.tactics_engine:refresh_all_units()
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
    end)

    self.event_bus:on("TACTICS_END_PLAYER_TURN", function()
        if self.phase ~= "PLAYER" then
            LOG.warn("Got message 'TACTICS_END_PLAYER_TURN', but phase was "..self.phase..".  Ignoring message.")
            return
        end

        LOG.info("End player turn!")

        self.event_bus:emit("TACTICS_BEGIN_ENEMY_TURN", self.tactics_engine)
    end)

    self.event_bus:on("TACTICS_BEGIN_ENEMY_TURN", function()
        self.phase = "ENEMY"
        LOG.info("Begin enemy turn!")
    end)

    self.event_bus:on("TACTICS_END_ENEMY_TURN", function()
        if self.phase ~= "ENEMY" then
            LOG.warn("Got message 'TACTICS_END_ENEMY_TURN', but phase was "..self.phase..".  Ignoring message.")
            return
        end
        LOG.info("End enemy turn!")

        self.turn = self.turn + 1

        local battle_result = self.battle_objective_service:check_for_end()

        if not battle_result.finished then
            self.event_bus:emit("TACTICS_BEGIN_PLAYER_TURN")
        else
            self.event_bus:emit(battle_result.command)
        end
    end)

    self.event_bus:on("BATTLE_END_VICTORY", function()
        LOG.info("You win!")
    end)

    self.event_bus:on("BATTLE_END_DEFEAT", function()
        LOG.info("You lose!")
    end)
    
    return self
end

return TurnManager
