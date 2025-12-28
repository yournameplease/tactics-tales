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
            ["APPEARANCE_OPTIONS"] = multiple_options_cursor.definition({
                primary_direction = "select",
                wrap = false,
                send_command = "GAME_SET_OPTIONS",
                options = {
                    multiple_options_cursor.option_definition({
                        text = "Body",
                        definition = list_cursor.integer_range(
                            1, 4,
                            "body",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Head shape",
                        definition = list_cursor.integer_range(
                            1, 2,
                            "head",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "hair",
                        definition = list_cursor.integer_range(
                            1, 2,
                            "hair",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Skin Color",
                        definition = list_cursor.integer_range(
                            1, 2,
                            "skin_color",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Hair Color",
                        definition = list_cursor.integer_range(
                            1, 2,
                            "hair_color",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Facial Hair",
                        definition = list_cursor.integer_range(
                            1, 2,
                            "beard",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Eyes",
                        definition = list_cursor.integer_range(
                            1, 2,
                            "eyes",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Eyewear",
                        definition = list_cursor.integer_range(
                            1, 2,
                            "eyewear",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Headwear",
                        definition = list_cursor.integer_range(
                            1, 2,
                            "headwear",
                            "horizontal"
                        ),
                    }),
                },
            }),
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

