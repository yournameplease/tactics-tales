local story = require("src/tactics/story/story")
local story_types = require("src/tactics/story/types")
local StoryId = story_types.StoryId
local MenuContext = require("src/tactics/menu/menu_context").MenuContext
local game_menu_manager = require("src/tactics/game/game_menu_manager")
local game_menu_context = require("src/tactics/game/game_menu_context")
local game_ui_context = require("src/tactics/game/game_ui_context")
local InputContext = require("src/tactics/input/input_context").InputContext
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle
local ConfigManager = require("src/tactics/config/config_manager").ConfigManager
local ModLoader = require("src/tactics/mods/mod_loader").ModLoader

local record Game
	menu_manager: game_menu_manager.GameMenuManager

    mod_loader: ModLoader

    default_story: StoryId
    story: story.Story

    services: GameServiceBundle
end

local game = {
    Game = Game
}

function Game:begin_story(ctx: MenuContext)
    local story_id = self.default_story
    if ctx.story ~= nil then
        story_id = ctx.story.id
    end

    local game_data = self.mod_loader:load_mod_data()
    self.story = story.new(story_id, game_data, self.services)
end

function Game:exit_story()
    self.story:teardown()
end

function game.new(
    services: GameServiceBundle,
    config_manager: ConfigManager,
    mod_loader: ModLoader
): Game 
    
    mod_loader:register_mod("base")
    local game_data = mod_loader:load_mod_data()

    local story_ids = game_data.stories.story_select
    
    local self: Game = setmetatable({}, { __index = Game })
    self.default_story = game_data.stories.default_story
    self.mod_loader = mod_loader
    self.services = services

    local game_menu_ctx = game_menu_context.new(
        story_ids
    )
	self.menu_manager = game_menu_manager.new(game_menu_ctx, self.services.event_bus)
    self.menu_manager:set_menu("MENU_MAIN_MENU")

    local game_ui_ctx = game_ui_context.new(self.services.event_bus, self.menu_manager, self.services.input_service)
    self.services.ui_context:register_ui_context(game_ui_ctx)

    self.services.event_bus:on("GAME_BEGIN_STORY", function(ctx: MenuContext)
        self:begin_story(ctx)
    end)
    self.services.event_bus:on("GAME_EXIT_STORY", function(_: MenuContext)
        self:exit_story()
    end)
    services.event_bus:on("GAME_SET_OPTIONS", function(ctx: MenuContext)
        log.debug(
            "TODO: set options: ",
            ctx.metadata["log_level"],
            ctx.metadata["draw_flexbox_debug"]
            )
        local config: DynamicConfig = {
        	log_level = ctx.metadata["log_level"] as LogLevel,
        	draw_flexbox_debug = ctx.metadata["draw_flexbox_debug"] as boolean,
        	draw_target_debug = ctx.metadata["draw_target_debug"] as boolean,
        }
        config_manager:store_config(config)
        log.debug(
            "Set options: ",
            config.log_level,
            config.draw_flexbox_debug,
            config.draw_target_debug
            )
        self.menu_manager:set_menu("MENU_MAIN_MENU")
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

return game
