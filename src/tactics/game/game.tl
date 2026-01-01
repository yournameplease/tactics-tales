require("src/tactics/debug")

local story = require("src/tactics/story/story")
local MenuContext = require("src/tactics/menu/menu_context").MenuContext
local game_menu_manager = require("src/tactics/game/game_menu_manager")
local game_menu_context = require("src/tactics/game/game_menu_context")
local game_ui_context = require("src/tactics/game/game_ui_context")
local InputContext = require("src/tactics/input/input_context").InputContext
local GameServiceBundle = require("src/tactics/systems/service/game_service_bundle").GameServiceBundle

local story_types = require("src/tactics/story/types")
local STORY_DATA = require("src/tactics/data/story")

local record Game
	menu_manager: game_menu_manager.GameMenuManager
       	
    story: story.Story

    services: GameServiceBundle
end

local game = {
    Game = Game
}

function Game:begin_story(ctx: MenuContext)
    local story_id = "test_story"
    if ctx.story ~= nil then
        story_id = ctx.story.id
    end
    self.story = story.new(story_id, self.services)
end

function Game:exit_story()
    self.story:teardown()
end

function game.new(services: GameServiceBundle): Game 

    local story_ids: {story_types.StoryId} = {}
    for id,_ in pairs(STORY_DATA) do
        pt.add(story_ids, id)
    end
    
    local self: Game = setmetatable({}, { __index = Game })
    self.services = services

    local game_menu_ctx = game_menu_context.new(
        story_ids
    )
	self.menu_manager = game_menu_manager.new(game_menu_ctx, self.services.event_bus)
    self.menu_manager:set_menu("MENU_MAIN_MENU")

    local game_ui_ctx = game_ui_context.new(self.services.event_bus, self.menu_manager)
    self.services.ui_context:register_ui_context(game_ui_ctx)

    self.services.event_bus:on("GAME_BEGIN_STORY", function(ctx: MenuContext)
        self:begin_story(ctx)
    end)
    self.services.event_bus:on("GAME_EXIT_STORY", function(_: MenuContext)
        self:exit_story()
    end)
    services.event_bus:on("GAME_SET_OPTIONS", function(ctx: MenuContext)
        LOG.debug(
            "TODO: set options: ",
            ctx.metadata["log_level"],
            ctx.metadata["draw_flexbox_debug"]
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
