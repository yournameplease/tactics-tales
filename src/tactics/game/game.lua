---@brief
--- The top-level manager for the overall game state.
--- It manages the main menu and transitions into campaigns.

local campaign = require("src.tactics.campaign.campaign")
local game_menu_manager = require("src.tactics.game.game_menu_manager")
local page_flip_animator = require("src.tactics.animation.page_flip_animator")
local game_ui_context = require("src.tactics.game.game_ui_context")
local event_listener = require("src.tactics.systems.event_bus.event_listener")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local save_system = require("src.tactics.save.save_system")

---@class CampaignServicesBundle Services needed to create a campaign.
---@field task_manager TaskManager
---@field animation_manager AnimationManager
---@field event_bus EventBus

---@class GameMenuContext : GameContext
---@field default_campaign_id string the campaign_id to use if starting from main
---@field campaign_ids CampaignId[] Available campaign IDs to present in the menu.
---@field campaigns table<CampaignId, CampaignDefinition> Available campaign IDs to present in the menu.
---@field handle_begin_campaign fun(save_id: string?, campaign_id: CampaignId, config: table<string, string>) Callback to start a new campaign.
---@field handle_load_campaign fun(save_id: string) Callback to load an existing campaign save.
---@field get_game_saves fun(): string[] Returns list of existing save IDs.
---@field config_manager ConfigManager
---@field page_flip_animator PageFlipAnimator Animator for menu step transitions.
---@field navigate_to fun(step: string) Navigate forward to a step (records history).
---@field navigate_back fun(target_step?: string) Navigate back, optionally to a named step.

---@class Game
---@field menu_manager GameMenuManager
---@field menu_page_flip_animator PageFlipAnimator
---@field mod_loader ModLoader
---@field config_manager ConfigManager
---@field default_campaign CampaignId
---@field campaign? Campaign
---@field event_listener EventListener
---@field event_writer EventWriter
---@field music_player MusicPlayer
---@field ui_context UIContextManager
---@field campaign_services_bundle CampaignServicesBundle
---@field input_service InputService
local Game = {}
Game.__index = Game

local game = {}

--- Load a campaign from a save file.
---@param file_name string Save file path.
function Game:load_campaign(file_name)
    local game_data = self.mod_loader:load_mod_data()
    self.campaign = campaign.load(
        file_name,
        game_data,
        self.campaign_services_bundle.task_manager,
        self.campaign_services_bundle.animation_manager,
        self.campaign_services_bundle.event_bus,
        self.music_player,
        self.ui_context,
        self.input_service
    )
end

--- Start a new campaign, either from scratch or from a save file.
---@param file_name string|nil Save file path, or nil for a new campaign.
---@param campaign_id CampaignId Campaign to start; defaults to the game's default campaign.
---@param config table<string, string>
function Game:begin_campaign(file_name, campaign_id, config)
    local game_data = self.mod_loader:load_mod_data()

    self.campaign = campaign.new(
        file_name,
        campaign_id,
        config,
        game_data,
        self.campaign_services_bundle.task_manager,
        self.campaign_services_bundle.animation_manager,
        self.campaign_services_bundle.event_bus,
        self.music_player,
        self.ui_context,
        self.input_service
    )
end

--- Persist the given config and return to the main menu.
---@param config DynamicConfig
function Game:set_config(config)
    self.config_manager:store_config(config)
    self.menu_manager:set_menu("MENU_MAIN_MENU")
end

--- Tear down the active campaign and return to the menu.
function Game:exit_campaign()
    self.campaign:teardown()
    self.campaign = nil
end

--- Return the active PageFlipAnimator: campaign's when in a campaign, menu's otherwise.
---@return PageFlipAnimator
function Game:page_flip_animator()
    if self.campaign ~= nil then
        return self.campaign:get_page_flip_animator()
    end
    return self.menu_page_flip_animator
end

--- Update game state for the current frame.
---@param input InputContext
function Game:update(input)
    if self.campaign ~= nil then
        self.campaign:update(input)
    else
        if not self.menu_page_flip_animator:is_blocking_input() then
            self.menu_manager:update(input)
        end
    end
end

--- Release event listeners and UI context registration.
function Game:teardown()
    self.ui_context:unregister_ui_context("game")
    self.event_listener:teardown()
end

--- Create and initialise a new Game instance.
---@param task_manager TaskManager
---@param animation_manager AnimationManager
---@param event_bus EventBus
---@param music_player MusicPlayer
---@param ui_context UIContextManager
---@param config_manager ConfigManager
---@param mod_loader ModLoader
---@param input_service InputService
---@return Game
function game.new(
    task_manager,
    animation_manager,
    event_bus,
    music_player,
    ui_context,
    config_manager,
    mod_loader,
    input_service
)
    mod_loader:register_mod("base")
    mod_loader:register_mod("tactics_puzzler")
    mod_loader:register_mod("tt_fantasy_demo_story")
    -- mod_loader:register_mod("tt_procedural_campaign")
    local game_data = mod_loader:load_mod_data()

    ---@type Game
    local self = setmetatable({}, Game)
    self.mod_loader = mod_loader
    self.config_manager = config_manager

    self.event_listener = event_listener.new(event_bus)
    self.event_writer = event_writer.new(event_bus)
    self.music_player = music_player

    self.menu_page_flip_animator = page_flip_animator.new()

    ---@type GameMenuContext
    local game_menu_ctx = {
        default_campaign_id = game_data.campaigns.default_campaign,
        campaign_ids = game_data.campaigns.campaign_select,
        campaigns = game_data.campaigns.data,
        config_manager = self.config_manager,
        get_game_saves = save_system.list_saves,
        handle_begin_campaign = function(file, id, config) self:begin_campaign(file, id, config) end,
        handle_load_campaign = function(file) self:load_campaign(file) end,
        -- filled in by game_menu_manager.new():
        page_flip_animator = self.menu_page_flip_animator,
        navigate_to = function(_) end,
        navigate_back = function(_) end,
    }
    self.menu_manager = game_menu_manager.new(game_menu_ctx, event_bus, self.menu_page_flip_animator)
    self.menu_manager:set_menu("MENU_MAIN_MENU")

    self.campaign_services_bundle = {
        task_manager = task_manager,
        animation_manager = animation_manager,
        event_bus = event_bus,
    }

    self.input_service = input_service
    local game_ui_ctx = game_ui_context.new(event_bus, self.menu_manager, input_service)
    self.ui_context = ui_context
    self.ui_context:register_ui_context(game_ui_ctx)

    self.event_listener:on("GAME_EXIT_CAMPAIGN", function()
        self:exit_campaign()
        self.menu_manager:set_menu("MENU_MAIN_MENU")
    end)

    return self
end

return game
