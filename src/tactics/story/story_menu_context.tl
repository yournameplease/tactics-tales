---@brief
--- Defines the context object for menus used within story scenes.

local character = require("src.tactics.character.object.character")

local record StoryMenuContext
	handle_create_character: function(appearance: {character.CharacterAppearanceKey: string})
end

local story_menu_context = {
    StoryMenuContext = StoryMenuContext
}

function story_menu_context.new(
	handle_create_character: function(appearance: {character.CharacterAppearanceKey: string})
): StoryMenuContext
    return {
        handle_create_character = handle_create_character,
    }
end

return story_menu_context
