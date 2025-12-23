local story_types = require("src/tactics/story/types")

local record GameMenuContext
    story_ids: {story_types.StoryId}
end

local game_menu_context = {
	GameMenuContext = GameMenuContext
}

function game_menu_context.new(story_ids: {story_types.StoryId} ): GameMenuContext
	return {
	    story_ids = story_ids
	}
end

return game_menu_context
