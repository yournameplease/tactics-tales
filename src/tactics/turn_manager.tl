require("src/tactics/debug")

require("src/tactics/battle/tactics/enemy_ai")
require("src/tactics/battle/battle_menu_manager")
require("src/tactics/util/data_utils")
require("src/tactics/systems/event_bus")
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")
require("src/tactics/systems/service")
require("src/tactics/battle/battle_objective_service")

local enum Phase
    "PLAYER"
    "ENEMY"
end

global record TurnManager
    turn: integer
    phase: Phase

    event_listener_ids: {integer}
    
    battle_map: BattleMap
    tactics_engine: tactics_engine.TacticsEngine
    battle_objective_service: BattleObjectiveService
    enemy_ai_engine: EnemyAIEngine
    battle_menu_manager : BattleMenuManager
    event_bus: EventBus
end

function TurnManager.new(
    battle_map: BattleMap,
    tactics_engine: tactics_engine.TacticsEngine,
    battle_objective_service: BattleObjectiveService,
    enemy_ai_engine: EnemyAIEngine,
    event_bus: EventBus,
    battle_menu_manager: BattleMenuManager
): TurnManager
    local self: TurnManager = setmetatable({
    }, { __index = TurnManager })

    self.turn = 1
    self.phase = "PLAYER"

    self.event_listener_ids = {}

    self.battle_map = battle_map 
    self.tactics_engine = tactics_engine 
    self.battle_objective_service = battle_objective_service
    self.enemy_ai_engine = enemy_ai_engine
    self.event_bus = event_bus 
    self.battle_menu_manager = battle_menu_manager

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_BEGIN_BATTLE", function()
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        self.event_bus:emit("TACTICS_BEGIN_PLAYER_TURN")
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_UNIT_END_ACTION", function()
        if self.phase == "PLAYER" then
            LOG.debug("Setting to player turn menu")
            self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
        end        
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_BEGIN_PLAYER_TURN", function()
        LOG.info("Begin player turn!")
        self.phase = "PLAYER"
        self.tactics_engine:refresh_all_units()
        self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_END_PLAYER_TURN", function()
        if self.phase ~= "PLAYER" then
            LOG.warn("Got message 'TACTICS_END_PLAYER_TURN', but phase was "..self.phase..".  Ignoring message.")
            return
        end

        LOG.info("End player turn!")

        self.event_bus:emit("TACTICS_BEGIN_ENEMY_TURN", self.tactics_engine)
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_BEGIN_ENEMY_TURN", function()
        self.phase = "ENEMY"
        LOG.info("Begin enemy turn!")
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_END_ENEMY_TURN", function()
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
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("BATTLE_END_VICTORY", function()
        LOG.info("You win!")
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("BATTLE_END_DEFEAT", function()
        LOG.info("You lose!")
    end))
    
    pt.add(self.event_listener_ids, self.event_bus:on("MOVE_AND_WAIT", function(ctx: MenuContext)
        self.tactics_engine:handle_move_unit(ctx)
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("MOVE_AND_ATTACK", function(ctx: MenuContext)
        self.tactics_engine:handle_move_and_attack(ctx)
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_BEGIN_PLAYER_TURN", function()
        self.tactics_engine.is_player_turn = true
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_END_PLAYER_TURN", function()
        self.tactics_engine.is_player_turn = false
    end))

    pt.add(self.event_listener_ids, self.event_bus:on("TACTICS_BEGIN_ENEMY_TURN", function()
        self.enemy_ai_engine:handle_enemy_turn()
    end))
    
    return self
end

function TurnManager:teardown()
    self.event_bus:remove_all(self.event_listener_ids)
end

return TurnManager
