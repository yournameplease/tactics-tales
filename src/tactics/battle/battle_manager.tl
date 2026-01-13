local InputContext = require("src/tactics/input/input_context").InputContext
local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local tactics_engine = require("src/tactics/battle/tactics/tactics_engine")
local map_generator = require("src/tactics/battle/map/map_generator")
local battle_menu_manager = require("src/tactics/battle/battle_menu_manager")
local battle_ui_context = require("src/tactics/battle/battle_ui_context")
local character_manager = require("src/tactics/character/character_manager")
local turn_manager = require("src/tactics/turn_manager")
local enemy_ai_engine = require("src/tactics/battle/tactics/enemy_ai")
local battle_objective_service = require("src/tactics/battle/battle_objective_service")
local battle_menu_context = require("src/tactics/battle/battle_menu_context")
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle
local GameData = require("src/tactics/game_data").GameData
local script_manager = require("src/tactics/battle/scripts/script_manager")

local record BattleManager

    battle_map: BattleMap

    tactics_engine: tactics_engine.TacticsEngine
    battle_objective_service: battle_objective_service.BattleObjectiveService
    enemy_ai_engine: enemy_ai_engine.EnemyAIEngine
    battle_menu_manager: battle_menu_manager.BattleMenuManager
    turn_manager: turn_manager.TurnManager
    script_manager: script_manager.ScriptManager

    character_manager: character_manager.CharacterManager

    services: GameServiceBundle
end

local battle_manager = {
    BattleManager = BattleManager
}

function battle_manager.new(
    battle_id: string,
    game_data: GameData,
    char_man: character_manager.CharacterManager,
    services: GameServiceBundle
): BattleManager 
    local self: BattleManager = setmetatable({}, { __index = BattleManager })
    self.services = services

    self.character_manager = char_man

    local battle_def = game_data.battles[battle_id]
    local map_def = game_data.maps[battle_def.map_id]
    self.battle_map = map_generator.load_map(map_def, battle_def.tile_labels)

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
        self.battle_map,
        self.tactics_engine
    )
    
    self.tactics_engine:spawn_all(
        battle_def.players,
        battle_def.enemies,
        battle_def.neutral,
        nil
    )

    self.battle_objective_service = battle_objective_service.new(
        self.battle_map,
        battle_def.victory_conditions,
        battle_def.failure_conditions
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
    self.battle_menu_manager = battle_menu_manager.new(
        battle_menu_ctx,
        self.services.event_bus
    )
    
    self.turn_manager = turn_manager.new(
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

    -- todo: re-enable when better or i add a mute button
    -- pt.music(0)
    return self
end

function BattleManager:teardown()
    pt.music(-1)
    self.services.ui_context:unregister_ui_context('battle')
    self.turn_manager:teardown()
    self.script_manager:teardown()
end

function BattleManager:update(input: InputContext)
    if not self.tactics_engine.battle_is_blocked then
        self.battle_menu_manager:update(input)
    end
    self.tactics_engine:update()
end

return battle_manager
