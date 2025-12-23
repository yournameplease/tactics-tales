require("src/tactics/debug")

require("src/tactics/types")
local Joypad = require("src/tactics/joypad").Joypad
require("src/tactics/systems/event_bus")
require("src/tactics/systems/tasks")

require("src/tactics/data/battles")

require("src/tactics/battle/battle_map")
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")
local map_generator = require("src/tactics/battle/map/map_generator")
require("src/tactics/menu/menu_manager")
require("src/tactics/ui/ui_context_manager")
local battle_ui_context = require("src/tactics/battle/battle_ui_context")
local character_manager = require("src/tactics/character/character_manager")
require("src/tactics/turn_manager")
local enemy_ai_engine = require("src/tactics/battle/tactics/enemy_ai")
local battle_objective_service = require("src/tactics/battle/battle_objective_service")
local battle_menu_context = require("src/tactics/battle/battle_context")
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle
local script_manager = require("src/tactics/battle/scripts/script_manager")

global record BattleManager

    battle_id: string
	
    battle_map: BattleMap

    tactics_engine: tactics_engine.TacticsEngine
    battle_objective_service: battle_objective_service.BattleObjectiveService
    enemy_ai_engine: enemy_ai_engine.EnemyAIEngine
    battle_menu_manager: BattleMenuManager
    turn_manager: TurnManager
    script_manager: script_manager.ScriptManager

    character_manager: character_manager.CharacterManager

    services: GameServiceBundle
end

function BattleManager.new(battle_id: string, char_man: character_manager.CharacterManager, services: GameServiceBundle): BattleManager 
    assert(BATTLE_DATA[battle_id] ~= nil)

    local self: BattleManager = setmetatable({}, { __index = BattleManager })
    self.services = services

    self.battle_id = battle_id
    self.character_manager = char_man

    local battle_def = BATTLE_DATA[self.battle_id]

    self.battle_map = map_generator.load_map(battle_def.map_id, battle_def.tile_labels)

    self.tactics_engine = tactics_engine.new(
        self.battle_map,
        self.character_manager,
        self.services.task_manager,
        self.services.animation_manager,
        self.services.event_bus
    )

    self.script_manager = script_manager.new(
        battle_def.scripts,
        self.services.event_bus,
        self.tactics_engine
    )
    
    self.tactics_engine:spawn_all(
        battle_def.players,
        battle_def.enemies,
        battle_def.neutral
    )

    self.battle_objective_service = battle_objective_service.new(
        self.battle_map
    )

    self.enemy_ai_engine = enemy_ai_engine.new(
        self.battle_map,
        self.tactics_engine,
        self.services.event_bus,
        self.services.task_manager
    )
    
    local battle_menu_ctx = battle_menu_context.new(
        self.battle_map,
        self.tactics_engine
    )
    self.battle_menu_manager = BattleMenuManager.new(
        battle_menu_ctx,
        self.services.event_bus
    )
    
    self.turn_manager = TurnManager.new(
        self.battle_map,
        self.tactics_engine,
        self.battle_objective_service,
        self.enemy_ai_engine,
        self.services.event_bus,
        self.battle_menu_manager
    )

    local battle_ui_ctx = battle_ui_context.new(
        self.battle_map,
        self.battle_menu_manager,
        self.turn_manager
    )
    self.services.ui_context:register_ui_context(battle_ui_ctx)

    self.services.event_bus:emit("TACTICS_BEGIN_BATTLE", {})
    return self
end

function BattleManager:teardown()
    self.services.ui_context:unregister_ui_context('battle')
    self.turn_manager:teardown()
    self.script_manager:teardown()
end

function BattleManager:update(joy: Joypad)
    self.battle_menu_manager:update(joy)
    self.tactics_engine:update()
end

return BattleManager
