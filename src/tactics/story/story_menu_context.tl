---@brief
--- Defines the context object for menus used within story scenes.

local character = require("src.tactics.character.object.character")
local menu_context = require("src.tactics.menu.menu_context")
local GameContext = menu_context.GameContext

local record StoryMenuContext
	is GameContext
	character_appearance: {character.CharacterAppearanceKey: string}
	handle_create_character: function(appearance: {character.CharacterAppearanceKey: string})
	handle_submit_text: function(text: string)
end

local story_menu_context = {
    StoryMenuContext = StoryMenuContext
}

function story_menu_context.new(
	handle_create_character: function(appearance: {character.CharacterAppearanceKey: string}),
	handle_submit_text: function(text: string)
): StoryMenuContext
    return {
        handle_create_character = handle_create_character,
        handle_submit_text = handle_submit_text,
    }
end

return story_menu_context
