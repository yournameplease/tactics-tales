---@brief
--- Manages the main game menu, including the title screen,
--- chapter select, and options menus.

local lists = require("src.tactics.util.lists")
local menu_types = require("src.tactics.menu.types")
local MenuContext = require ("src.tactics.menu.menu_context").MenuContext
local menu_manager = require("src.tactics.menu.menu_manager")
local step_definition = menu_manager.definition.step
local event_bus = require("src.tactics.systems.event_bus")
local GameMenuContext = require("src.tactics.game.game_menu_context").GameMenuContext
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local list = require("src.tactics.menu.cursor.nested.list")
local button = require("src.tactics.menu.cursor.button")
local ButtonDefinition = button.ButtonDefinition
local selection = require("src.tactics.menu.cursor.selection")
local story = require("src.tactics.story.types")
local StoryId = story.StoryId

local record GameMenuManager
    is menu_manager.MenuManager
end

local game_menu_manager = {
    GameMenuManager = GameMenuManager
}

local record MainMenuContext
    is MenuContext
    selected_file: string
end

local HANDLERS: { menu_types.MenuHandlerId: menu_manager.MenuHandler } = {}

HANDLERS["store_selected_save"] = function(
    _services: GameMenuContext,
    _menu_data: {string: any},
    session_context: MainMenuContext,
    file: StoryId
): menu_manager.menu_handler.MenuHandlerPostHandling
    session_context.selected_file = file

    return nil
end

HANDLERS["begin_file"] = function(
    services: GameMenuContext,
    _menu_data: {string: any},
    _session_context: MainMenuContext,
    file: string
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.handle_begin_story(file, nil)

    return nil
end

HANDLERS["begin_file_from_context"] = function(
    services: GameMenuContext,
    _menu_data: {string: any},
    session_context: MainMenuContext,
    _story_id: StoryId
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.handle_begin_story(session_context.selected_file, nil)

    return nil
end

HANDLERS["load_story"] = function(
    services: GameMenuContext,
    _menu_data: {string: any},
    _session_context: MainMenuContext,
    file: StoryId
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.handle_load_story(file)

    return nil
end

HANDLERS["begin_chapter"] = function(
    services: GameMenuContext,
    _menu_data: {string: any},
    _session_context: MainMenuContext,
    story_id: StoryId
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.handle_begin_story(nil, story_id)

    return nil
end

HANDLERS["set_options"] = function(
    services: GameMenuContext,
    menu_data: DynamicConfig,
    _session_context: MainMenuContext,
    _value: any
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.config_manager:store_config(menu_data)

    return nil
end

HANDLERS["reset_options"] = function(
    services: GameMenuContext,
    _menu_data: DynamicConfig,
    _session_context: MainMenuContext,
    _value: any
): menu_manager.menu_handler.MenuHandlerPostHandling
    services.config_manager:reset_config()

    return nil
end

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition } = {
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
                    function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}

                        pt.add(options, button.builder("begin_story")
                            :with_text("New Game")
                            :advance_to("NEW_FILE_SELECT"))
                        pt.add(options, button.builder("load_story")
                            :with_text("Load Game")
                            :advance_to("LOAD_FILE_SELECT"))
                        pt.add(options, button.builder("to_chapter_select")
                            :with_text("Chapter Select")
                            :advance_to("CHAPTER_SELECT"))
                        pt.add(options, button.builder("to_options")
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
                    function(msb: GameMenuContext, _ctx: MainMenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}
                        local existing_files = msb.get_game_saves()

                        for i = 1,5 do
                            local file_name = "file_"..i
                            local b = button.builder(file_name)
                                :with_text("File "..i)
                                :with_value(file_name)

                            if lists.contains(existing_files, file_name) then
                                b = b:handle_action("select", "store_selected_save")
                                    :advance_to("CONFIRM_FILE")
                            else
                                b = b:handle_action("select", "begin_file")
                            end
                            pt.add(options, b)
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
                    function(_msb: GameMenuContext, ctx: MainMenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}

                        pt.add(options, button.builder("label") --lol
                            :with_text("Confirm overwrite "..ctx.selected_file .."?"))
                        pt.add(options, button.builder("confirm_overwrite") 
                            :with_text("Confirm")
                            :handle_action("select", "begin_file_from_context")
                            :as_final_step())
                        pt.add(options, button.builder("no_overwrite") 
                            :advance_to("NEW_FILE")
                            :with_text("Back"))

                        return options
                    end
                )
            )
            :with_previous_step("NEW_FILE")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["LOAD_FILE_SELECT"] = step_definition.of_node(
                list.column(
                    "load_file_select",
                    function(msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}
                        local existing_files = msb.get_game_saves()

                        for _,file_name in ipairs(existing_files) do
                            local b = button.builder(file_name)
                                :with_text(file_name)
                                :with_value(file_name)
                                :handle_action("select", "load_story")

                            pt.add(options, b)
                        end

                        return options
                    end
                )
            )
            :with_previous_step("MAIN_MENU")
            :with_action("BUTTON_A", { command = "select", description = "Select"})
            :with_action("BUTTON_B", { command = "back", description = "Back"}),
            ["CHAPTER_SELECT"] = step_definition.of_node(
                list.column(
                    "chapter_select",
                    function(msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}

                        for _,story_id in ipairs(msb.story_ids) do
                            pt.add(options, button.builder("begin_story_"..story_id)
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
                    function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local children: {MenuNodeDefinition} = {}

                        pt.add(children, list.column(
                            "options_selections",
                            function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                                local options: {MenuNodeDefinition} = {}
                                pt.add(options, selection.row("log_level")
                                    :with_label("Log Level")
                                    :with_key("log_level")
                                    :with_static_options({"ERROR", "WARNING", "INFO", "DEBUG", "TRACE"}))
                                pt.add(options, selection.row("draw_flexbox_debug")
                                    :with_label("Draw Flexbox Debug")
                                    :with_key("draw_flexbox_debug")
                                    :with_yes_no_options())
                                pt.add(options, selection.row("profile")
                                    :with_label("Profiler")
                                    :with_key("profile")
                                    :with_yes_no_options())
                                pt.add(options, selection.row("head_scale")
                                    :with_label("Head Scale")
                                    :with_key("head_scale")
                                    :with_static_options({1, 2, 3, 0.75, 0}))
                                pt.add(options, selection.row("dialogue_speed")
                                    :with_label("Text Speed")
                                    :with_key("dialogue_speed")
                                    :with_static_options({
                                        	"very_slow",
                                        	"slow",
                                        	"normal",
                                        	"fast",
                                        	"very_fast",
                                        	"instant",
                                        }))
                                pt.add(options, selection.row("glyph_family")
                                    :with_label("Glyphs")
                                    :with_key("glyph_family")
                                    :with_static_options({
                                        	"keyboard",
                                        	"picotron",
                                        	"snes",
                                        	"nintendo",
                                        	"xbox",
                                        	"playstation",
                                        }))
                                return options
                            end))
                            
                        pt.add(children, list.row(
                            "options_navigation",
                            function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                                local options: {MenuNodeDefinition} = {}
                                pt.add(options, button.builder("back")
                                    :with_text("Back")
                                    :advance_to("MAIN_MENU"))
                                pt.add(options, button.builder("reset")
                                    :with_text("Defaults")
                                    :handle_action("select", "reset_options")
                                    :advance_to("MAIN_MENU"))
                                pt.add(options, button.builder("save")
                                    :with_text("Save")
                                    :handle_action("select", "set_options")
                                    :advance_to("MAIN_MENU"))
                                return options
                            end))

                        return children
                    end
                )
            ):with_initial_data(function(_services: GameMenuContext, _session_data: MenuContext): {string: any}
                return DYNAMIC_CONFIG
            end)
            :with_action("BUTTON_A", { command = "select", description = "Select"}),
        }
    }

}

function game_menu_manager.new(ctx: GameMenuContext, bus: event_bus.EventBus): GameMenuManager
    return menu_manager.new(
        MENU_DATA,
        HANDLERS,
        ctx,
        bus
    ) as GameMenuManager
end

return game_menu_manager

