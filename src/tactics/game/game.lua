---@brief
--- The top-level manager for the overall game state.
--- It manages the main menu and transitions into stories.

local story = require("src.tactics.story.story")
local game_menu_manager = require("src.tactics.game.game_menu_manager")
local game_menu_context = require("src.tactics.game.game_menu_context")
local game_ui_context = require("src.tactics.game.game_ui_context")
local event_listener = require("src.tactics.systems.event_bus.event_listener")
local event_writer = require("src.tactics.systems.event_bus.event_writer")

---@class StoryServicesBundle Services needed to create a story.
---@field task_manager TaskManager
---@field animation_manager AnimationManager
---@field event_bus EventBus

---@class Game
---@field menu_manager GameMenuManager
---@field mod_loader ModLoader
---@field config_manager ConfigManager
---@field default_story StoryId
---@field story Story|nil
---@field event_listener EventListener
---@field event_writer EventWriter
---@field music_player MusicPlayer
---@field ui_context UIContextManager
---@field story_services_bundle StoryServicesBundle
local Game = {}
Game.__index = Game

local game = {}

--- Load a story from a save file.
---@param file_name string Save file path.
function Game:load_story(file_name)
    local game_data = self.mod_loader:load_mod_data()
    self.story = story.load(
        file_name,
        game_data,
        self.story_services_bundle.task_manager,
        self.story_services_bundle.animation_manager,
        self.story_services_bundle.event_bus,
        self.music_player,
        self.ui_context
    )
end

--- Start a new story, either from scratch or from a save file.
---@param file_name string|nil Save file path, or nil for a new story.
---@param story_id StoryId|nil Story to start; defaults to the game's default story.
function Game:begin_story(file_name, story_id)
    local game_data = self.mod_loader:load_mod_data()
    if file_name == nil then -- unsaved story
        assert(story_id)
        self.story = story.new(
            nil,
            story_id,
            game_data,
            self.story_services_bundle.task_manager,
            self.story_services_bundle.animation_manager,
            self.story_services_bundle.event_bus,
            self.music_player,
            self.ui_context
        )
        return
    end

    story_id = story_id or self.default_story

    self.story = story.new(
        file_name,
        story_id,
        game_data,
        self.story_services_bundle.task_manager,
        self.story_services_bundle.animation_manager,
        self.story_services_bundle.event_bus,
        self.music_player,
        self.ui_context
    )
end

--- Persist the given config and return to the main menu.
---@param config DynamicConfig
function Game:set_config(config)
    self.config_manager:store_config(config)
    self.menu_manager:set_menu("MENU_MAIN_MENU")
end

--- Tear down the active story and return to the menu.
function Game:exit_story()
    self.story:teardown()
    self.story = nil
end

--- Update game state for the current frame.
---@param input InputContext
function Game:update(input)
    if self.story ~= nil then
        self.story:update(input)
    else
        self.menu_manager:update(input)
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
    local game_data = mod_loader:load_mod_data()

    local story_ids = game_data.stories.story_select

    ---@type Game
    local self = setmetatable({}, Game)
    self.default_story = game_data.stories.default_story
    self.mod_loader = mod_loader
    self.config_manager = config_manager

    self.event_listener = event_listener.new(event_bus)
    self.event_writer = event_writer.new(event_bus)
    self.music_player = music_player

    local game_menu_ctx = game_menu_context.new(
        story_ids,
        function(file, id) self:begin_story(file, id) end,
        function(file) self:load_story(file) end,
        self.config_manager
    )
    self.menu_manager = game_menu_manager.new(game_menu_ctx, event_bus)
    self.menu_manager:set_menu("MENU_MAIN_MENU")

    self.story_services_bundle = {
        task_manager = task_manager,
        animation_manager = animation_manager,
        event_bus = event_bus,
    }

    local game_ui_ctx = game_ui_context.new(event_bus, self.menu_manager, input_service)
    self.ui_context = ui_context
    self.ui_context:register_ui_context(game_ui_ctx)

    self.event_listener:on("GAME_EXIT_STORY", function()
        self:exit_story()
    end)

    return self
end

return game
