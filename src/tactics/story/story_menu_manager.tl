local menu_types = require("src/tactics/menu/types")
local MenuContext = require ("src/tactics/menu/menu_context").MenuContext
local sprite_data = require("src/tactics/character/sprite_data")
local customization_options = sprite_data.customization_options
local menu_manager = require("src/tactics/menu/menu_manager")
local StoryMenuContext = require("src/tactics/story/story_menu_context").StoryMenuContext
local character = require("src/tactics/character/object/character")
local CharacterAppearanceKey = character.CharacterAppearanceKey
local event_bus = require("src/tactics/systems/event_bus")
local button_advance_cursor = require("src/tactics/menu/cursor/button_advance_cursor")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")

local lists = require("src/tactics/util/lists")

local function set_character_customization_option(
    key: CharacterAppearanceKey
): function(cursor: list_cursor.ListMenuCursor<StoryMenuContext, string>, _: StoryMenuContext, mc: MenuContext)
    return function(cursor: list_cursor.ListMenuCursor<StoryMenuContext, string>, _: StoryMenuContext, mc: MenuContext)
		if mc.character_customization == nil then
			mc.character_customization = {}
		end
		if mc.character_customization.appearance == nil then
			mc.character_customization.appearance = {}
		end
		log.debug("storing context", key, cursor.options[cursor.i].value)
		mc.character_customization.appearance[key] = cursor.options[cursor.i].value
	end
end

local function list_cursor_definition_for_part(
    key: CharacterAppearanceKey,
    options: {{ string, sprite_data.NamedSpriteData }}
): list_cursor.ListMenuDefinition<StoryMenuContext, string>
    local cursor_options = lists.map(
		function(option: {string, sprite_data.NamedSpriteData}): list_cursor.ListMenuOption<StoryMenuContext, string>
        	return {
            	text = option[2].name,
            	value = option[1],
        	}
    	end
	)(options)
    
    return list_cursor.definition({
        set_selected_context = set_character_customization_option(key),

        get_options = function(_: StoryMenuContext, _: MenuContext): {list_cursor.ListMenuOption<string>}
            return cursor_options
        end,
        
        wrap = true,
        direction = "horizontal",
    })
end

local function multiple_option_cursor_for_part(
    key: CharacterAppearanceKey,
    text: string,
	options: { string },
    data: { string: sprite_data.NamedSpriteData }
): multiple_options_cursor.MenuMultipleOptionDefinition<StoryMenuContext>
	local data_list = lists.map(
		function(id: string): {string, sprite_data.NamedSpriteData}
			return { id, data[id]}
		end
	)(options)

    return multiple_options_cursor.option_definition({
            text = text,
			key = key,
            definition = list_cursor_definition_for_part(key, data_list),
            must_select = false,
        })
end

local function menu_definition_for_character_select(): multiple_options_cursor.MultipleOptionsMenuDefinition<StoryMenuContext>
    return multiple_options_cursor.definition({
        primary_direction = "vertical",
        wrap = false,
        send_command = "STORY_CREATE_CHARACTER",
        options = {
            multiple_option_cursor_for_part("head", "Head", customization_options.HEAD, sprite_data.HEAD),
            multiple_option_cursor_for_part("hair", "Hair", customization_options.HAIR, sprite_data.HAIR),
            multiple_option_cursor_for_part("skin", "Skin Color", customization_options.SKIN_COLOR, sprite_data.SKIN_COLOR),
            multiple_option_cursor_for_part("hair_color", "Hair Color", customization_options.HAIR_COLOR, sprite_data.COLOR_NAMES),
            multiple_option_cursor_for_part("body_class", "Body", customization_options.BODY_CLASS, sprite_data.BODY_CLASS),
            multiple_option_cursor_for_part("beard", "Facial Hair", customization_options.FACIAL_HAIR, sprite_data.FACIAL_HAIR),
            multiple_option_cursor_for_part("eyes", "Eyes", customization_options.EYES, sprite_data.EYES),
            multiple_option_cursor_for_part("eyewear", "Eyewear", customization_options.EYEWEAR, sprite_data.EYEWEAR),
            multiple_option_cursor_for_part("headwear", "Headwear", customization_options.HEADWEAR, sprite_data.HEADWEAR),
        }
    })
end


local record StoryMenuManager
    is menu_manager.MenuManager<StoryMenuContext>
end

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition<StoryMenuContext> } = {
    ["MENU_STORY_TEXT"] = {
        initial_step = "ADVANCE_TEXT",
        steps = {
            ["ADVANCE_TEXT"] = button_advance_cursor.definition({
                send_command = "STORY_ADVANCE_TEXT"
            }),
        }
    },
    ["MENU_CUSTOMIZE_CHARACTER"] = {
        initial_step = "APPEARANCE_OPTIONS",
        steps = {
            ["APPEARANCE_OPTIONS"] = menu_definition_for_character_select(),
        }
    }
}

local story_menu_manager = {
    StoryMenuManager = StoryMenuManager,
}

function story_menu_manager.new(ctx: StoryMenuContext, bus: event_bus.EventBus): StoryMenuManager
    return menu_manager.new(
        MENU_DATA,
        ctx,
        bus
    ) as StoryMenuManager
end

return story_menu_manager

