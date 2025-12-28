require("src/tactics/debug")
require("src/tactics/types")
require("src/tactics/menu/types")
require("src/tactics/menu/menu_manager")
require("src/tactics/joypad")
require("src/tactics/story/story_page")
require("src/tactics/systems/service")
require("src/tactics/menu/menu_manager")
require("src/tactics/story/story_context")
local event_bus = require("src/tactics/systems/event_bus")
local button_advance_cursor = require("src/tactics/menu/cursor/button_advance_cursor")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")

local lists = require("src/tactics/util/lists")

local record CharacterCustomizationPartOption<Value>
    text: string
    value: Value
end

local record CharacterCustomizationPart<Value>
    key: string
    text: string
    options: { CharacterCustomizationPartOption<Value> }
end

local CHARACTER_CUSTOMIZATION_OPTIONS: { string: CharacterCustomizationPart<any> } = {
	HEAD = {
		key = "head",
        text = "Head",
		options = {
			{text = "A" , value = 64},
			{text = "B" , value = 68},
		},
	},
	HAIR = {
		key = "hair",
        text = "Hair",
		options = {
			{text = "A" , value = 72},
			{text = "B" , value = 73},
			{text = "C" , value = 74},
			{text = "D" , value = 75},
			{text = "E" , value = 77},
			{text = "F" , value = 80},
			{text = "G" , value = 81},
			{text = "H" , value = 82},
			{text = "I" , value = 83},
			{text = "J" , value = 85},
			{text = "K" , value = 80},
		},
	},
	SKIN = {
		key = "skin",
        text = "Skin",
		options = {
			{text = "A" , value = 1},
			{text = "B" , value = 2},
			{text = "C" , value = 3},
			{text = "D" , value = 4},
		},
	},
	HAIR_COLOR = {
		key = "hair_color",
        text = "Hair Color",
		options = {
			{text = "4" , value = 4},
			{text = "5" , value = 5},
			{text = "6" , value = 6},
			{text = "9" , value = 9},
			{text = "10" , value = 10},
			{text = "20" , value = 20},
			{text = "21" , value = 21},
			{text = "22" , value = 22},
			{text = "24" , value = 24},
			{text = "25" , value = 25},
			{text = "31" , value = 31},
		},
	},
	BODY_CLASS = {
		key = "body_class",
        text = "Body",
		options = {
			{text = "Default" , value = "DEFALUT"},
			{text = "Sleeveless" , value = "SLEEVELESS"},
			{text = "Shirtless" , value = "SHIRTLESS"},
			{text = "Robe" , value = "ROBED"},
		},
	},
	BEARD = {
		key = "beard",
        text = "Facial Hair",
		options = {
			{text = "None" , value = nil},
			{text = "Unshaven" , value = 89},
			{text = "Mustache" , value = 90},
			{text = "Sideburns" , value = 91},
			{text = "Beard" , value = 92},
			{text = "Goatee" , value = 93},
			{text = "Bushy Beard" , value = 94},
		},
	},
	EYES = {
		key = "eyes",
        text = "Eyes",
		options = {
			{text = "A" , value = 120},
		},
	},
	EYEWEAR = {
		key = "eyewear",
        text = "Eyewear",
		options = {
			{text = "None" , value = nil},
			{text = "Glasses" , value = 96},
			{text = "Mask" , value = 102},
		},
	},
	HEADWEAR = {
		key = "headwear",
        text = "Headwear",
		options = {
			{text = "None" , value = nil},
			{text = "Wizard Hat" , value = "wizard_hat"},
			{text = "Hood" , value = "hood"},
			{text = "Covered Hood" , value = "cultist_hood"},
			{text = "Hooded Wizard Hat" , value = "hooded_wizard_hat"},
			{text = "Hat" , value = "fancy_hat"},
			{text = "Animal Mask" , value = "animal_mask"},
		},
	},
}

local function set_character_customization_option<Value>(cursor: list_cursor.ListMenuCursor<StoryMenuContext, Value>, _: StoryMenuContext, mc: MenuContext)
    -- todo
    
    assert("not implemented")
end

local function list_cursor_definition_for_part<Value>(part_data: CharacterCustomizationPart<Value>): list_cursor.ListMenuDefinition<StoryMenuContext, Value>
    local options = lists.map(function(o: CharacterCustomizationPartOption<Value>): list_cursor.ListMenuOption<Value>
        return {
            text = o.text,
            value = o.value,
        }
    end)(part_data.options)
    
    return list_cursor.definition({
        set_selected_context = set_character_customization_option,

        get_options = function(_: StoryMenuContext, _: MenuContext): {list_cursor.ListMenuOption<Value>}
            return options
        end,
        
        wrap = true,
        direction = "horizontal",
    })
end

local function multiple_option_cursor_for_part<Value>(part_data: CharacterCustomizationPart<Value>): multiple_options_cursor.MenuMultipleOptionDefinition<StoryMenuContext>
    -- local part_data = CHARACTER_CUSTOMIZATION_OPTIONS[id]
    return multiple_options_cursor.option_definition({
            text = part_data.text,
            definition = list_cursor_definition_for_part(part_data),
            must_select = false,
        })
end

local function menu_definition_for_character_select(): multiple_options_cursor.MultipleOptionsMenuDefinition<StoryMenuContext>
    return multiple_options_cursor.definition({
        primary_direction = "select",
        wrap = false,
        send_command = "GAME_SET_OPTIONS",
        options = {
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["HEAD"]),
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["HAIR"]),
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["SKIN"]),
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["HAIR_COLOR"]),
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["BODY_CLASS"]),
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["BEARD"]),
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["EYES"]),
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["EYEWEAR"]),
            multiple_option_cursor_for_part(CHARACTER_CUSTOMIZATION_OPTIONS["HEADWEAR"]),
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
    return BaseMenuManager.new(
        MENU_DATA,
        ctx,
        bus
    ) as StoryMenuManager
end

return StoryMenuManager

