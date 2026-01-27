local story_types = require("src/tactics/story/types")
local StoryId = story_types.StoryId

local record GameMenuContext
    story_ids: {StoryId}
	handle_set_config: function(DynamicConfig)
	handle_begin_story: function(StoryId)
end

local game_menu_context = {
	GameMenuContext = GameMenuContext
}

function game_menu_context.new(
	story_ids: {story_types.StoryId},
	handle_set_config: function(DynamicConfig),
	handle_begin_story: function(StoryId)
): GameMenuContext
	return {
	    story_ids = story_ids,
		handle_set_config = handle_set_config,
		handle_begin_story = handle_begin_story,
	}
end

return game_menu_context
