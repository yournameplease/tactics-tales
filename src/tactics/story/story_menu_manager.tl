require("src/tactics/debug")
require("src/tactics/types")
require("src/tactics/menu/types")
require("src/tactics/menu/menu_manager")
require("src/tactics/joypad")
require("src/tactics/story/story_page")
require("src/tactics/systems/service")
local sprite_data = require("src/tactics/character/sprite_data")
local menu_manager = require("src/tactics/menu/menu_manager")
local StoryMenuContext = require("src/tactics/story/story_context").StoryMenuContext
require("src/tactics/character/object/character")
local event_bus = require("src/tactics/systems/event_bus")
local button_advance_cursor = require("src/tactics/menu/cursor/button_advance_cursor")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")

local lists = require("src/tactics/util/lists")
local maps = require("src/tactics/util/maps")

local function set_character_customization_option(
    key: CharacterAppearanceKey
): function(cursor: list_cursor.ListMenuCursor<StoryMenuContext, string>, _: StoryMenuContext, mc: MenuContext)
    -- todo
    return function(cursor: list_cursor.ListMenuCursor<StoryMenuContext, string>, _: StoryMenuContext, mc: MenuContext)
		if mc.character_customization == nil then
			mc.character_customization = {}
		end
		if mc.character_customization.appearance == nil then
			mc.character_customization.appearance = {}
		end
		mc.character_customization.appearance[key] = cursor.options[cursor.i].value
	end
end

local function list_cursor_definition_for_part(
    key: CharacterAppearanceKey,
    options: { string: sprite_data.NamedSpriteData }
): list_cursor.ListMenuDefinition<StoryMenuContext, string>
    local cursor_options = maps.to_list(maps.map(function(id: string, data: sprite_data.NamedSpriteData): list_cursor.ListMenuOption<string>
        return {
            text = data.name,
            value = id,
        }
    end)(options))
    
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
    options: { string: sprite_data.NamedSpriteData }
): multiple_options_cursor.MenuMultipleOptionDefinition<StoryMenuContext>
    -- local part_data = CHARACTER_CUSTOMIZATION_OPTIONS[id]
    return multiple_options_cursor.option_definition({
            text = text,
			key = key,
            definition = list_cursor_definition_for_part(key, options),
            must_select = false,
        })
end

local function menu_definition_for_character_select(): multiple_options_cursor.MultipleOptionsMenuDefinition<StoryMenuContext>
    return multiple_options_cursor.definition({
        primary_direction = "vertical",
        wrap = false,
        send_command = "STORY_CREATE_CHARACTER",
        options = {
            multiple_option_cursor_for_part("head", "Head", sprite_data.HEAD),
            multiple_option_cursor_for_part("hair", "Hair", sprite_data.HAIR),
            multiple_option_cursor_for_part("skin", "Skin Color", sprite_data.SKIN_COLOR),
            multiple_option_cursor_for_part("hair_color", "Hair Color",
				maps.collect(
					lists.merge(sprite_data.NATURAL_HAIR_COLORS, sprite_data.UNNATURAL_HAIR_COLORS),
					function(color: string): string return color end,
					function(color: string): sprite_data.NamedColor return sprite_data.COLOR_NAMES[color] end
				)),
            multiple_option_cursor_for_part("body_class", "Body", sprite_data.BODY_CLASS),
            multiple_option_cursor_for_part("beard", "Facial Hair", sprite_data.FACIAL_HAIR),
            multiple_option_cursor_for_part("eyes", "Eyes", sprite_data.EYES),
            multiple_option_cursor_for_part("eyewear", "Eyewear", sprite_data.EYEWEAR),
            multiple_option_cursor_for_part("headwear", "Headwear", sprite_data.HEADWEAR),
        }
    })
end


global record StoryMenuManager
    is MenuManager<StoryMenuContext>
end

local MENU_DATA: { MenuId: MenuDefinition<StoryMenuContext> } = {
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

function StoryMenuManager.new(ctx: StoryMenuContext, bus: event_bus.EventBus): StoryMenuManager
    return menu_manager.new(
        MENU_DATA,
        ctx,
        bus
    ) as StoryMenuManager
end

return StoryMenuManager

