---@brief
--- The main manager for a battle instance.
--- It initializes and coordinates all battle-related services,
--- including the tactics engine, UI, menus, and AI.

local InputContext = require("src.tactics.input.input_context").InputContext
local bm = require("src.tactics.battle.battle_map")
local tactics_engine = require("src.tactics.battle.tactics.tactics_engine")
local map_generator = require("src.tactics.battle.map.map_generator")
local battle_menu_manager = require("src.tactics.battle.battle_menu_manager")
local battle_ui_context = require("src.tactics.battle.battle_ui_context")
local turn_manager = require("src.tactics.turn_manager")
local ai_engine = require("src.tactics.battle.tactics.ai_engine")
local battle_objective_service = require("src.tactics.battle.battle_objective_service")
local battle_menu_context = require("src.tactics.battle.battle_menu_context")
local script_manager = require("src.tactics.battle.scripts.script_manager")
local CharacterManager = require("src.tactics.character.character_manager").CharacterManager
local EventBus = require("src.tactics.systems.event_bus").EventBus
local GameData = require("src.tactics.game_data").GameData
local TaskManager = require("src.tactics.systems.tasks").TaskManager
local AnimationManager = require("src.tactics.animation").AnimationManager
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager

local interface BattleManager
    teardown: function(self)
    update: function(self, input: InputContext)
end

local battle_manager = {
    BattleManager = BattleManager
}

local record BattleManagerImpl
    is BattleManager

    battle_map: bm.BattleMap

    tactics_engine: tactics_engine.TacticsEngine
    battle_objective_service: battle_objective_service.BattleObjectiveService
    enemy_ai_engine: ai_engine.AIEngine
    battle_menu_manager: battle_menu_manager.BattleMenuManager
    turn_manager: turn_manager.TurnManager
    script_manager: script_manager.ScriptManager

    character_manager: CharacterManager
    ui_context: UIContextManager
end

function battle_manager.new(
    battle_id: string,
    game_data: GameData,
    char_man: CharacterManager,
    task_manager: TaskManager,
    animation_manager: AnimationManager,
    event_bus: EventBus,
    ui_context: UIContextManager
): BattleManager 
    local self: BattleManagerImpl = setmetatable({}, { __index = BattleManagerImpl })

    self.character_manager = char_man

    local battle_def = game_data.battles[battle_id]
    local map_def = game_data.maps[battle_def.map_id]
    self.battle_map = map_generator.load_map(map_def, battle_def.tile_labels)

    self.tactics_engine = tactics_engine.new(
        self.battle_map,
        self.character_manager,
        task_manager,
        animation_manager,
        event_bus
    )

    self.script_manager = script_manager.new(
        battle_def.scripts,
        event_bus,
        self.battle_map,
        self.tactics_engine,
        task_manager
    )
    
    self.tactics_engine:spawn_all(
        battle_def.players,
        battle_def.enemies,
        battle_def.neutral,
        nil,
        "prevent"
    )

    self.battle_objective_service = battle_objective_service.new(
        self.battle_map,
        battle_def.turn_limit,
        battle_def.victory_conditions,
        battle_def.failure_conditions
    )

    self.enemy_ai_engine = ai_engine.new(
        self.battle_map,
        self.tactics_engine,
        task_manager
    )
    
    local battle_menu_ctx = battle_menu_context.new(
        self.battle_map,
        self.tactics_engine,
        battle_def.deployment and battle_def.deployment.deployment_tiles_tag or nil,
        function() event_bus:emit("TACTICS_BEGIN_BATTLE", {}) end
    )
    self.battle_menu_manager = battle_menu_manager.new(
        battle_menu_ctx,
        event_bus
    )
    
    self.turn_manager = turn_manager.new(
        self.battle_map,
        self.tactics_engine,
        self.battle_objective_service,
        self.enemy_ai_engine,
        event_bus,
        task_manager,
        self.battle_menu_manager
    )

    local battle_ui_ctx = battle_ui_context.new(
        self.battle_map,
        self.battle_menu_manager,
        self.tactics_engine,
        self.turn_manager,
        self.battle_objective_service
    )
    self.ui_context = ui_context
    self.ui_context:register_ui_context(battle_ui_ctx)

    if battle_def.deployment ~= nil then
        self.tactics_engine:spawn_all(
            {{ character_source = {type = "player_roster"}, tile = "player_deployment" }},
            {},
            {},
            nil,
            "prevent"
        )
        self.battle_menu_manager:set_menu("MENU_DEPLOYMENT")
    else
        event_bus:emit("TACTICS_BEGIN_BATTLE", {})
    end

    -- todo: re-enable when better or i add a mute button
    -- pt.music(0)
    return self
end

function BattleManagerImpl:teardown()
    pt.music(-1)
    self.ui_context:unregister_ui_context('battle')
    self.turn_manager:teardown()
    self.script_manager:teardown()
end

function BattleManagerImpl:update(input: InputContext)
    if not self.tactics_engine:is_hard_blocked() then
        self.battle_menu_manager:update(input)
    end
    self.tactics_engine:update(input)
end

return battle_manager
