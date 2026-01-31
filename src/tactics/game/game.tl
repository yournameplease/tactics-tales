local story = require("src.tactics.story.story")
local story_types = require("src.tactics.story.types")
local StoryId = story_types.StoryId
local game_menu_manager = require("src.tactics.game.game_menu_manager")
local game_menu_context = require("src.tactics.game.game_menu_context")
local game_ui_context = require("src.tactics.game.game_ui_context")
local event_listener = require("src.tactics.systems.event_bus.event_listener")
local event_writer = require("src.tactics.systems.event_bus.event_writer")
local InputContext = require("src.tactics.input.input_context").InputContext
local ConfigManager = require("src.tactics.config.config_manager").ConfigManager
local ModLoader = require("src.tactics.mods.mod_loader").ModLoader
local EventBus = require("src.tactics.systems.event_bus").EventBus
local InputService = require("src.tactics.joypad").InputService
local TaskManager = require("src.tactics.systems.tasks").TaskManager
local AnimationManager = require("src.tactics.animation").AnimationManager
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager

---@desc
--- services needed to create a story
local record StoryServicesBundle
    task_manager: TaskManager
    animation_manager: AnimationManager
    event_bus: EventBus
end

local record Game
	menu_manager: game_menu_manager.GameMenuManager

    mod_loader: ModLoader
    config_manager: ConfigManager

    default_story: StoryId
    story: story.Story

    event_listener: event_listener.EventListener
    event_writer: event_writer.EventWriter

    ui_context: UIContextManager

    story_services_bundle: StoryServicesBundle
end

local game = {
    Game = Game
}

function Game:begin_story(story_id: StoryId)
    story_id = story_id or self.default_story

    local game_data = self.mod_loader:load_mod_data()
    self.story = story.new(
        story_id,
        game_data,
        self.story_services_bundle.task_manager,
        self.story_services_bundle.animation_manager,
        self.story_services_bundle.event_bus,
        self.ui_context
    )
end

function Game:set_config(config: DynamicConfig)
    self.config_manager:store_config(config)
    self.menu_manager:set_menu("MENU_MAIN_MENU")
end

function Game:exit_story()
    self.story:teardown()
    self.story = nil
end

function game.new(
    task_manager: TaskManager,
    animation_manager: AnimationManager,
    event_bus: EventBus,
    ui_context: UIContextManager,
    config_manager: ConfigManager,
    mod_loader: ModLoader,
    input_service: InputService
): Game 
    
    mod_loader:register_mod("base")
    local game_data = mod_loader:load_mod_data()

    local story_ids = game_data.stories.story_select
    
    local self: Game = setmetatable({}, { __index = Game })
    self.default_story = game_data.stories.default_story
    self.mod_loader = mod_loader
    self.config_manager = config_manager

    self.event_listener = event_listener.new(event_bus)
    self.event_writer = event_writer.new(event_bus)

    local game_menu_ctx = game_menu_context.new(
        story_ids,
        function(config: DynamicConfig) self:set_config(config) end,
        function(id: StoryId) self:begin_story(id) end
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

function Game:update(input: InputContext)
    if self.story ~= nil then
        self.story:update(input)
    else
        self.menu_manager:update(input)
    end
end

function Game:teardown()
    self.ui_context:unregister_ui_context("game")
    self.event_listener:teardown()
end

return game
