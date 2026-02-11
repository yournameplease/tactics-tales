---@brief
--- Defines the context object for the main game menu system.

local story_types = require("src.tactics.story.types")
local StoryId = story_types.StoryId
local menu_context = require("src.tactics.menu.menu_context")
local GameContext = menu_context.GameContext
local ConfigManager = require("src.tactics.config.config_manager").ConfigManager

local record GameMenuContext
	is GameContext
    story_ids: {StoryId}
	handle_begin_story: function(StoryId)
    config_manager: ConfigManager
end

local game_menu_context = {
	GameMenuContext = GameMenuContext
}

function game_menu_context.new(
	story_ids: {story_types.StoryId},
	handle_begin_story: function(StoryId),
    config_manager: ConfigManager
): GameMenuContext
	return {
	    story_ids = story_ids,
		config_manager = config_manager,
		handle_begin_story = handle_begin_story,
	}
end

return game_menu_context
