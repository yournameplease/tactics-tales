---@brief
--- The main manager for a battle instance.
--- It initializes and coordinates all battle-related services,
--- including the tactics engine, UI, menus, and AI.

local tactics_engine = require("src.tactics.battle.tactics.tactics_engine")
local map_generator = require("src.tactics.battle.map.map_generator")
local battle_menu_manager = require("src.tactics.battle.battle_menu_manager")
local battle_ui_context = require("src.tactics.battle.battle_ui_context")
local turn_manager = require("src.tactics.battle.turn_manager")
local ai_engine = require("src.tactics.battle.tactics.ai_engine")
local battle_objective_service = require("src.tactics.battle.battle_objective_service")
local script_manager = require("src.tactics.battle.scripts.script_manager")

---@class BattleMenuContext : GameContext
---@field deployment_tiles_tag string Tag identifying tiles available for unit deployment.
---@field battle_map BattleMap
---@field tactics_engine TacticsEngine
---@field handle_start_battle fun() Callback invoked when the player starts the battle.
---@field handle_end_turn fun() Callback invoked when the player ends their turn.
---@field tutorial_mode boolean When true, hides Wait and End Turn to force scripted actions.

---@class BattleConfig
---@field permadeath boolean

---@class BattleManager Abstract interface for a battle instance.
---@field teardown fun(self: BattleManager) Tear down all battle services and unregister UI.
---@field update fun(self: BattleManager, input: InputContext) Process one frame of battle input and logic.

---@class BattleManagerImpl : BattleManager
---@field battle_map BattleMap
---@field tactics_engine TacticsEngine
---@field battle_objective_service BattleObjectiveService
---@field enemy_ai_engine AIEngine
---@field battle_menu_manager BattleMenuManager
---@field turn_manager TurnManager
---@field script_manager ScriptManager
---@field character_manager CharacterManager
---@field ui_context UIContextManager
---@field music_player MusicPlayer
local BattleManagerImpl = {}
BattleManagerImpl.__index = BattleManagerImpl

local battle_manager = {
}

--- Create and initialize a new BattleManager for the given battle.
---@param chapter integer
---@param battle_id BattleId
---@param campaign_config CampaignConfig
---@param rng_context CampaignRngContext?
---@param battle_config BattleConfig
---@param game_data GameData
---@param char_man CharacterManager
---@param task_manager TaskManager
---@param animation_manager AnimationManager
---@param event_bus EventBus
---@param music_player MusicPlayer
---@param ui_context UIContextManager
---@param input_service InputService
---@return BattleManager
function battle_manager.new(
    chapter,
    battle_id,
    campaign_config,
    rng_context,
    battle_config,
    game_data,
    char_man,
    task_manager,
    animation_manager,
    event_bus,
    music_player,
    ui_context,
    input_service
)
    log.debug("Starting battle: " .. battle_id)
    ---@type BattleManagerImpl
    local self = setmetatable({}, BattleManagerImpl)

    self.character_manager = char_man
    self.music_player = music_player

    local battle_def = game_data.missions[battle_id](campaign_config, rng_context)
    local map_def = game_data.maps[battle_def.map_id]
    log.debug("Loading map '" ..
        tostring(battle_def.map_id) ..
        "' type='" .. tostring(map_def and map_def.type) .. "' file='" .. tostring(map_def and map_def.file) .. "'")
    self.battle_map = map_generator.load_map(map_def, battle_def.tile_labels, game_data.gfx_registry)
    log.debug("Generated battle map with size " .. self.battle_map.width .. "x" .. self.battle_map.height .. ".")

    self.tactics_engine = tactics_engine.new(
        chapter,
        battle_config,
        self.battle_map,
        self.character_manager,
        task_manager,
        animation_manager,
        event_bus,
        music_player,
        game_data.skills
    )

    self.tactics_engine:spawn_all(
        battle_def.units,
        nil,
        "prevent"
    )

    self.script_manager = script_manager.new(
        battle_def.scripts,
        event_bus,
        music_player,
        self.battle_map,
        self.tactics_engine,
        task_manager
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

    local begin_battle = function()
        event_bus:emit("TACTICS_BEGIN_BATTLE", {
            chapter = chapter,
            battle_id = battle_id,
        })
    end

    ---@type BattleMenuContext
    local battle_menu_ctx = {
        battle_map = self.battle_map,
        tactics_engine = self.tactics_engine,
        deployment_tiles_tag = battle_def.deployment and battle_def.deployment.deployment_tiles_tag or nil,
        handle_start_battle = begin_battle,
        handle_end_turn = function() event_bus:emit("TACTICS_FINISH_SIDE_ACTIONS", {}) end,
        tutorial_mode = false,
    }
    self.script_manager.battle_menu_ctx = battle_menu_ctx
    self.battle_menu_manager = battle_menu_manager.new(
        battle_menu_ctx,
        event_bus
    )

    self.turn_manager = turn_manager.new(
        chapter,
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
        self.battle_objective_service,
        input_service
    )
    self.enemy_ai_engine.on_unit_action = function(unit)
        battle_ui_ctx:move_camera(self.battle_map, unit.tile, STATIC_CONFIG.CAMERA_DEAD_ZONE_ENEMY)
    end
    self.ui_context = ui_context
    self.ui_context:register_ui_context(battle_ui_ctx)

    if battle_def.music then
        -- todo: move this to after deployment phase
        music_player:set_music(battle_def.music, 0)
    end

    if battle_def.deployment ~= nil then
        self.tactics_engine:spawn_all(
            { {
                side = "player",
                character_source = { type = "player_roster" },
                tile = "player_deployment"
            } },
            nil,
            "prevent"
        )
        self.battle_menu_manager:set_menu("MENU_DEPLOYMENT")
    else
        begin_battle()
    end

    return self
end

--- Tear down all battle services and unregister the battle UI context.
function BattleManagerImpl:teardown()
    self.music_player:clear_music()
    self.ui_context:unregister_ui_context('battle')
    self.turn_manager:teardown()
    self.script_manager:teardown()
end

--- Process one frame of battle input and logic.
---@param input InputContext
function BattleManagerImpl:update(input)
    if not self.tactics_engine:is_hard_blocked() then
        self.battle_menu_manager:update(input)
    end
    self.tactics_engine:update(input)
end

return battle_manager
