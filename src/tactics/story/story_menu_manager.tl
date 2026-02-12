---@brief
--- Manages menus that appear during story sequences, such as
--- the character customization screen.

local menu_types = require("src.tactics.menu.types")
local MenuContext = require ("src.tactics.menu.menu_context").MenuContext
local sprite_data = require("src.tactics.character.sprite_data")
local customization_options = sprite_data.customization_options
local menu_manager = require("src.tactics.menu.menu_manager")
local step_definition = menu_manager.definition.step
local StoryMenuContext = require("src.tactics.story.story_menu_context").StoryMenuContext
local character = require("src.tactics.character.object.character")
local CharacterAppearanceKey = character.CharacterAppearanceKey
local event_bus = require("src.tactics.systems.event_bus")
local list = require("src.tactics.menu.cursor.nested.list")
local button = require("src.tactics.menu.cursor.button")
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local selection = require("src.tactics.menu.cursor.selection")
local SelectionMenuDefinition = selection.SelectionMenuDefinition
local SelectionOption = selection.SelectionMenuOption

local lists = require("src.tactics.util.lists")

local function list_cursor_options_for_part(
    options: {{ string, sprite_data.NamedSpriteData }}
): {SelectionOption}
    local cursor_options = lists.map(
		function(option: {string, sprite_data.NamedSpriteData}): SelectionOption
        	return {
            	text = option[2].name,
            	value = option[1],
        	}
    	end
	)(options)
    
    return cursor_options
end

local function multiple_option_cursor_for_part(
    key: CharacterAppearanceKey,
    text: string,
	options: { string },
    data: { string: sprite_data.NamedSpriteData }
): SelectionMenuDefinition
	local data_list = lists.map(
		function(id: string): {string, sprite_data.NamedSpriteData}
			return { id, data[id]}
		end
	)(options)

    return selection.row(key.."_selection")
            :with_label(text)
			:with_key(key)
			:with_precomputed_options(list_cursor_options_for_part(data_list))
end

local function menu_definition_for_character_select(): menu_manager.MenuStepDefinition
    return step_definition.of_node(
        list.column(
            "character_creation_menu",
            function(_msb: StoryMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                local children: {MenuNodeDefinition} = {}
                pt.add(children, list.column( 
                    "appearance_selections",
      
                    function(_msb: StoryMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {MenuNodeDefinition} = {}
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

                        -- pt.add(children, )
                        return options
                    end))

                pt.add(children, list.row( 
                    "character_creation",
                    function(_msb: StoryMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {MenuNodeDefinition} = {}
                        pt.add(options, button.builder("confirm")
                            :with_text("Confirm")
                            :handle_select("create_character"))
                        return options
                    end))

                return children
            end))
end


local record StoryMenuManager
    is menu_manager.MenuManager
end

local HANDLERS: { menu_types.MenuHandlerId: menu_manager.MenuHandler } = {}

HANDLERS["create_character"] = function(
    services: StoryMenuContext,
    menu_data: {string: any},
    _session_context: MenuContext,
    _value: any
)
    local appearance = menu_data as {character.CharacterAppearanceKey: string}
    services.handle_create_character(appearance)
end

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition } = {
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
        HANDLERS,
        ctx,
        bus
    ) as StoryMenuManager
end

return story_menu_manager

