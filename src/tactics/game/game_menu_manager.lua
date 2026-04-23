---@brief
--- Manages the main game menu, including the title screen,
--- chapter select, and options menus.

local lists = require("src.tactics.util.lists")
local menu_manager = require("src.tactics.menu.menu_manager")
local step_definition = menu_manager.definition.step
local list = require("src.tactics.menu.cursor.nested.list")
local button = require("src.tactics.menu.cursor.button")
local selection = require("src.tactics.menu.cursor.selection")

---@class GameMenuManager : MenuManager

local game_menu_manager = {}

---@class MainMenuContext : MenuContext
---@field selected_file string The save file name chosen by the player for overwrite confirmation.

---@type table<string, MenuHandler>
local HANDLERS = {}

--- Store the selected save file name in session context for the overwrite confirmation step.
---@param _services GameMenuContext
---@param _menu_data table<string, any>
---@param session_context MainMenuContext
---@param file StoryId
---@return MenuHandlerPostHandling?
HANDLERS["store_selected_save"] = function(_services, _menu_data, session_context, file)
    session_context.selected_file = file
    return nil
end

--- Begin a story using the file name stored in session context.
---@param services GameMenuContext
---@param menu_data table<string, string>
---@param session_context MainMenuContext
---@param _value string
---@return MenuHandlerPostHandling?
HANDLERS["begin_file_from_context"] = function(
    services,
    menu_data,
    session_context,
    _value
)
    services.handle_begin_story(session_context.selected_file, services.default_story_id, menu_data)
    return nil
end

--- Load an existing story save by file name.
---@param services GameMenuContext
---@param _menu_data table<string, any>
---@param _session_context MainMenuContext
---@param file StoryId
---@return MenuHandlerPostHandling?
HANDLERS["load_story"] = function(services, _menu_data, _session_context, file)
    services.handle_load_story(file)
    return nil
end

--- Begin a story chapter directly by story ID.
---@param services GameMenuContext
---@param _menu_data table<string, any>
---@param _session_context MainMenuContext
---@param story_id StoryId
---@return MenuHandlerPostHandling?
HANDLERS["begin_chapter"] = function(services, _menu_data, _session_context, story_id)
    services.handle_begin_story(nil, story_id, {}) -- TODO: Config?  Or default config?
    return nil
end

--- Persist the current options menu data to config.
---@param services GameMenuContext
---@param menu_data DynamicConfig
---@param _session_context MainMenuContext
---@param _value any
---@return MenuHandlerPostHandling?
HANDLERS["set_options"] = function(services, menu_data, _session_context, _value)
    services.config_manager:store_config(menu_data)
    return nil
end

--- Reset config to defaults.
---@param services GameMenuContext
---@param _menu_data DynamicConfig
---@param _session_context MainMenuContext
---@param _value any
---@return MenuHandlerPostHandling?
HANDLERS["reset_options"] = function(services, _menu_data, _session_context, _value)
    services.config_manager:reset_config()
    return nil
end

---@type table<string, MenuDefinition>
local MENU_DATA = {
    ["MENU_MAIN_MENU"] = {
        initial_step = "TITLE_SCREEN",
        steps = {
            ["TITLE_SCREEN"] = step_definition.of_node(
                button.builder("to_main_menu")
                :with_text("Main Menu")
                :advance_to("MAIN_MENU")
            )
            :with_default_lmb("select")
            :with_action("BUTTON_A", { command = "select", description = "Start"}),
            ["MAIN_MENU"] = step_definition.of_node(
                list.column(
                    "main_menu",
                    function(_msb, _ctx)
                        local options = {}

                        table.insert(options, button.builder("begin_story")
                            :with_text("New Game")
                            :advance_to("NEW_FILE_SELECT"))
                        table.insert(options, button.builder("load_story")
                            :with_text("Load Game")
                            :advance_to("LOAD_FILE_SELECT"))
                        table.insert(options, button.builder("to_chapter_select")
                            :with_text("Chapter Select")
                            :advance_to("CHAPTER_SELECT"))
                        table.insert(options, button.builder("to_options")
                            :with_text("Options")
                            :advance_to("OPTIONS_MENU"))

                        return options
                    end
                )
            )
            :with_previous_step("TITLE_SCREEN")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["NEW_FILE_SELECT"] = step_definition.of_node(
                list.column(
                    "new_file_select",
                    function(msb, _ctx)
                        ---@cast msb GameMenuContext
                        local options = {}
                        local existing_files = msb.get_game_saves()

                        for i = 1, 5 do
                            local file_name = "file_" .. i
                            local b = button.builder(file_name)
                                :with_text("File " .. i)
                                :with_value(file_name)

                            if lists.contains(existing_files, file_name) then
                                b = b:handle_action("select", "store_selected_save")
                                    :advance_to("CONFIRM_FILE")
                            else
                                b = b:handle_action("select", "store_selected_save")
                                    :advance_to("STORY_CONFIG")
                            end
                            table.insert(options, b)
                        end

                        return options
                    end
                )
            )
            :with_previous_step("MAIN_MENU")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["CONFIRM_FILE"] = step_definition.of_node(
                list.column(
                    "confirm_file",
                    function(_msb, ctx)
                        ---@cast ctx MainMenuContext
                        local options = {}

                        table.insert(options, button.builder("label")
                            :with_text("Confirm overwrite " .. ctx.selected_file .. "?"))
                        table.insert(options, button.builder("confirm_overwrite")
                            :with_text("Confirm")
                            :advance_to("STORY_CONFIG"))
                        table.insert(options, button.builder("no_overwrite")
                            :advance_to("NEW_FILE_SELECT")
                            :with_text("Back"))

                        return options
                    end
                )
            )
            :with_previous_step("NEW_FILE_SELECT")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["LOAD_FILE_SELECT"] = step_definition.of_node(
                list.column(
                    "load_file_select",
                    function(msb, _ctx)
                        ---@cast msb GameMenuContext
                        local options = {}
                        local existing_files = msb.get_game_saves()

                        for _, file_name in ipairs(existing_files) do
                            local b = button.builder(file_name)
                                :with_text(file_name)
                                :with_value(file_name)
                                :handle_action("select", "load_story")

                            table.insert(options, b)
                        end

                        return options
                    end
                )
            )
            :with_previous_step("MAIN_MENU")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["STORY_CONFIG"] = step_definition.of_node(
                list.column(
                    "confirm_file",
                    function(msb, ctx)
                        ---@cast msb GameMenuContext
                        ---@cast ctx MainMenuContext
                        local options = {}

                        local story_id = msb.default_story_id
                        local definition = msb.stories[story_id]
                        local config = definition.config

                        if config then
                            for _, opt in ipairs(config) do
                                local b = selection.row(opt.key)
                                    :with_key(opt.key)
                                    :with_label(opt.name)
                                    :with_description(opt.description)

                                for _,o in ipairs(opt.options) do
                                    b = b:with_static_option{
                                        value = o.value,
                                        text = o.name,
                                        description = o.description,
                                    }
                                end

                                table.insert(options, b)
                            end
                        end
                        
                        table.insert(options, button.builder("confirm_begin")
                            :with_text("Begin")
                            :handle_action("select", "begin_file_from_context")
                            :as_final_step())
                        table.insert(options, button.builder("no_begin")
                            :advance_to("NEW_FILE_SELECT")
                            :with_text("Back"))

                        return options
                    end
                )
            )
            :with_previous_step("NEW_FILE_SELECT")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["CHAPTER_SELECT"] = step_definition.of_node(
                list.column(
                    "chapter_select",
                    function(msb, _ctx)
                        ---@cast msb GameMenuContext
                        local options = {}

                        for _, story_id in ipairs(msb.story_ids) do
                            table.insert(options, button.builder("begin_story_" .. story_id)
                                :with_text(story_id)
                                :with_value(story_id)
                                :handle_action("select", "begin_chapter"))
                        end

                        return options
                    end
                )
            )
            :with_previous_step("MAIN_MENU")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["OPTIONS_MENU"] = step_definition.of_node(
                list.column(
                    "options_menu",
                    function(_msb, _ctx)
                        local children = {}

                        table.insert(children, list.column(
                            "options_selections",
                            function(_msb2, _ctx2)
                                local options = {}
                                table.insert(options, selection.row("log_level")
                                    :with_label("Log Level")
                                    :with_key("log_level")
                                    :with_static_option_flat("ERROR")
                                    :with_static_option_flat("WARNING")
                                    :with_static_option_flat("INFO")
                                    :with_static_option_flat("DEBUG")
                                    :with_static_option_flat("TRACE"))
                                table.insert(options, selection.row("draw_flexbox_debug")
                                    :with_label("Draw Flexbox Debug")
                                    :with_key("draw_flexbox_debug")
                                    :with_description("")
                                    :with_static_option_flat(true, "YES")
                                    :with_static_option_flat(false, "NO"))
                                table.insert(options, selection.row("profile")
                                    :with_label("Profiler")
                                    :with_key("profile")
                                    :with_description("")
                                    :with_static_option_flat(true, "YES")
                                    :with_static_option_flat(false, "NO"))
                                table.insert(options, selection.row("head_scale")
                                    :with_label("Head Scale")
                                    :with_key("head_scale")
                                    :with_description("")
                                    :with_static_option_flat(1, "Normal")
                                    :with_static_option_flat(2, "Large")
                                    :with_static_option_flat(3, "Huge")
                                    :with_static_option_flat(0.75, "Small")
                                    :with_static_option_flat(0, "Headless"))
                                table.insert(options, selection.row("dialogue_speed")
                                    :with_label("Text Speed")
                                    :with_key("dialogue_speed")
                                    :with_description("")
                                    :with_static_option_flat("very_slow", "Very Slow")
                                    :with_static_option_flat("slow", "Slow")
                                    :with_static_option_flat("normal", "Normal")
                                    :with_static_option_flat("fast", "Fast")
                                    :with_static_option_flat("very_fast", "Very Fast")
                                    :with_static_option_flat("instant", "Instant"))
                                table.insert(options, selection.row("glyph_family")
                                    :with_label("Glyphs")
                                    :with_key("glyph_family")
                                    :with_description("Glyphs to display for joypad inputs")
                                    :with_static_option_flat("keyboard", "Keyboard")
                                    :with_static_option_flat("picotron", "Picotron")
                                    :with_static_option_flat("snes", "SNES")
                                    :with_static_option_flat("nintendo", "Nintendo")
                                    :with_static_option_flat("xbox", "Xbox")
                                    :with_static_option_flat("playstation", "PlayStation"))
                                table.insert(options, selection.row("input_group")
                                    :with_label("Input Mode")
                                    :with_key("input_group")
                                    :with_description("Limit to specific input modes")
                                    :with_static_option_flat("mouse_and_keyboard", "Mouse and Joypad", "Allows either mouse or joypad (including keyboard)")
                                    :with_static_option_flat("mouse_only", "Mouse Only", "Mouse controls only")
                                    :with_static_option_flat("joy_only", "Joypad Only", "Joypad/keyboard controls only"))
                                return options
                            end))

                        table.insert(children, list.row(
                            "options_navigation",
                            function(_msb2, _ctx2)
                                local options = {}
                                table.insert(options, button.builder("back")
                                    :with_text("Back")
                                    :advance_to("MAIN_MENU"))
                                table.insert(options, button.builder("reset")
                                    :with_text("Defaults")
                                    :handle_action("select", "reset_options")
                                    :advance_to("MAIN_MENU"))
                                table.insert(options, button.builder("save")
                                    :with_text("Save")
                                    :handle_action("select", "set_options")
                                    :advance_to("MAIN_MENU"))
                                return options
                            end))

                        return children
                    end
                )
            ):with_initial_data(function(_services, _session_data)
                return DYNAMIC_CONFIG
            end)
            :with_action("BUTTON_A", { command = "select", description = "Select"}),
        }
    }
}

--- Create a new GameMenuManager for the main game menu.
---@param ctx GameMenuContext
---@param bus EventBus
---@return GameMenuManager
function game_menu_manager.new(ctx, bus)
    return menu_manager.new(
        MENU_DATA,
        HANDLERS,
        ctx,
        bus
    ) --[[@as GameMenuManager]]
end

return game_menu_manager
