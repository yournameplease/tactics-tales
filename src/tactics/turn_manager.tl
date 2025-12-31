require("src/tactics/debug")

local enemy_ai_engine = require("src/tactics/battle/tactics/enemy_ai")
local event_bus = require("src/tactics/systems/event_bus")
local event_listener = require("src/tactics/systems/event_bus/event_listener")
local event_writer = require("src/tactics/systems/event_bus/event_writer")
local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local BattleMenuManager = require("src/tactics/battle/battle_menu_manager").BattleMenuManager
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")
local battle_objective_service = require("src/tactics/battle/battle_objective_service")

local enum Phase
    "PLAYER"
    "ENEMY"
end

local interface TurnManager
    turn: integer
    phase: Phase

    teardown: function(self)
end

local turn_manager = {
    TurnManager = TurnManager
}

local record TurnManagerImpl
    is TurnManager

    battle_map: BattleMap
    tactics_engine: tactics_engine.TacticsEngine
    battle_objective_service: battle_objective_service.BattleObjectiveService
    enemy_ai_engine: enemy_ai_engine.EnemyAIEngine
    battle_menu_manager : BattleMenuManager

    event_listener: event_listener.EventListener
    event_writer: event_writer.EventWriter
end

function turn_manager.new(
    map: BattleMap,
    tactics_eng: tactics_engine.TacticsEngine,
    battle_objective_srv: battle_objective_service.BattleObjectiveService,
    enemy_ai_eng: enemy_ai_engine.EnemyAIEngine,
    bus: event_bus.EventBus,
    battle_menu_manager: BattleMenuManager
): TurnManager
    local self: TurnManagerImpl = setmetatable({
    }, { __index = TurnManager })

    self.turn = 1
    self.phase = "PLAYER"

    self.battle_map = map 
    self.tactics_engine = tactics_eng
    self.battle_objective_service = battle_objective_srv
    self.enemy_ai_engine = enemy_ai_eng
    self.battle_menu_manager = battle_menu_manager

    self.event_listener = event_listener.new(bus)
    self.event_writer = event_writer.new(bus)

    self.event_listener:on("TACTICS_BEGIN_BATTLE", function(_: event_bus.EventArgs)
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        self.event_writer:emit("TACTICS_BEGIN_PLAYER_TURN", {
            turn = self.turn
        })
    end)

    self.event_listener:on("TACTICS_UNIT_END_ACTION", function(_: event_bus.EventArgs)
        if self.phase == "PLAYER" then
            LOG.debug("Setting to player turn menu")
            self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        end        
    end)

    self.event_listener:on("TACTICS_BEGIN_PLAYER_TURN", function(_: event_bus.EventArgs)
        LOG.info("Begin player turn!")
        self.phase = "PLAYER"
        self.tactics_engine:refresh_all_units()
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
    end)

    self.event_listener:on("TACTICS_END_PLAYER_TURN", function(_: event_bus.EventArgs)
        if self.phase ~= "PLAYER" then
            LOG.warn("Got message 'TACTICS_END_PLAYER_TURN', but phase was "..self.phase..".  Ignoring message.")
            return
        end

        LOG.info("End player turn!")

        self.event_writer:emit("TACTICS_BEGIN_ENEMY_TURN", {
            turn = self.turn
        })
    end)

    self.event_listener:on("TACTICS_BEGIN_ENEMY_TURN", function(_: event_bus.EventArgs)
        self.phase = "ENEMY"
        LOG.info("Begin enemy turn!")
    end)

    self.event_listener:on("TACTICS_END_ENEMY_TURN", function(_: event_bus.EventArgs)
        if self.phase ~= "ENEMY" then
            LOG.warn("Got message 'TACTICS_END_ENEMY_TURN', but phase was "..self.phase..".  Ignoring message.")
            return
        end
        LOG.info("End enemy turn!")

        self.turn = self.turn + 1

        local battle_result = self.battle_objective_service:check_for_end()

        if not battle_result.finished then
            self.event_writer:emit("TACTICS_BEGIN_PLAYER_TURN", {
            turn = self.turn
        })
        else
            self.event_writer:emit(battle_result.command, {})
        end
    end)

    self.event_listener:on("BATTLE_END_VICTORY", function()
        LOG.info("You win!")
    end)

    self.event_listener:on("BATTLE_END_DEFEAT", function()
        LOG.info("You lose!")
    end)
    
    self.event_listener:on("MOVE_AND_WAIT", function(ctx: MenuContext)
        self.tactics_engine:handle_move_unit(ctx)
    end)

    self.event_listener:on("MOVE_AND_ATTACK", function(ctx: MenuContext)
        self.tactics_engine:handle_move_and_attack(ctx)
    end)

    self.event_listener:on("TACTICS_BEGIN_PLAYER_TURN", function(_: event_bus.EventArgs)
        self.tactics_engine.is_player_turn = true
    end)

    self.event_listener:on("TACTICS_END_PLAYER_TURN", function(_: event_bus.EventArgs)
        self.tactics_engine.is_player_turn = false
    end)

    self.event_listener:on("TACTICS_BEGIN_ENEMY_TURN", function(_: event_bus.EventArgs)
        self.enemy_ai_engine:handle_enemy_turn()
    end)

    self.event_listener:on("TACTICS_FINISH_ENEMY_ACTIONS", function()
        self.event_writer:emit("TACTICS_END_ENEMY_TURN", {
            turn = self.turn
        })
    end)

    self.event_listener:on("TACTICS_FINISH_PLAYER_ACTIONS", function()
        self.event_writer:emit("TACTICS_END_PLAYER_TURN", {
            turn = self.turn
        })
    end)
    
    return self
end

function TurnManagerImpl:teardown()
    self.event_listener:teardown()
end

return turn_manager
