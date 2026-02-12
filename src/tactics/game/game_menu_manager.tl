---@brief
--- Manages the main game menu, including the title screen,
--- chapter select, and options menus.

local menu_types = require("src.tactics.menu.types")
local MenuContext = require ("src.tactics.menu.menu_context").MenuContext
local menu_manager = require("src.tactics.menu.menu_manager")
local step_definition = menu_manager.definition.step
local event_bus = require("src.tactics.systems.event_bus")
local GameMenuContext = require("src.tactics.game.game_menu_context").GameMenuContext
local GameMainMenuContext = require("src.tactics.menu.menu_context").GameMainMenuContext
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

local HANDLERS: { menu_types.MenuHandlerId: menu_manager.MenuHandler } = {}

HANDLERS["begin_story"] = function(
    services: GameMenuContext,
    _menu_data: {string: any},
    _session_context: GameMainMenuContext,
    story_id: StoryId
)
    services.handle_begin_story(story_id)
end

HANDLERS["set_options"] = function(
    services: GameMenuContext,
    menu_data: DynamicConfig,
    _session_context: GameMainMenuContext,
    _value: any
)
    services.config_manager:store_config(menu_data)
end

HANDLERS["reset_options"] = function(
    services: GameMenuContext,
    _menu_data: DynamicConfig,
    _session_context: GameMainMenuContext,
    _value: any
)
    services.config_manager:reset_config()
end

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition } = {
    ["MENU_MAIN_MENU"] = {
        initial_step = "TITLE_SCREEN",
        steps = {
            ["TITLE_SCREEN"] = step_definition.of_node(
                button.builder("to_main_menu")
                :with_text("Main Menu")
                :advance_to("MAIN_MENU")
            ):with_default_lmb("button_primary"),
            ["MAIN_MENU"] = step_definition.of_node(
                list.column(
                    "main_menu",
                    function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}

                        pt.add(options, button.builder("begin_story")
                            :with_text("Play")
                            :handle_select("begin_story"))
                        pt.add(options, button.builder("to_chapter_select")
                            :with_text("Chapter Select")
                            :advance_to("CHAPTER_SELECT"))
                        pt.add(options, button.builder("to_options")
                            :with_text("Options")
                            :advance_to("OPTIONS_MENU"))

                        return options
                    end
                )
            ),
            ["CHAPTER_SELECT"] = step_definition.of_node(
                list.column(
                    "chapter_select",
                    function(msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}

                        for _,story_id in ipairs(msb.story_ids) do
                            pt.add(options, button.builder("begin_story_"..story_id)
                                :with_text(story_id)
                                :with_value(story_id)
                                :handle_select("begin_story"))
                        end

                        return options
                    end
                )
            ),
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
                                pt.add(options, selection.row("draw_target_debug")
                                    :with_label("Draw Target Debug")
                                    :with_key("draw_target_debug")
                                    :with_yes_no_options())
                                pt.add(options, selection.row("profile")
                                    :with_label("Profiler")
                                    :with_key("profile")
                                    :with_yes_no_options())
                                pt.add(options, selection.row("head_scale")
                                    :with_label("Head Scale")
                                    :with_key("head_scale")
                                    :with_static_options({1, 2, 3, 4}))
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
                                    :handle_select("reset_options")
                                    :advance_to("MAIN_MENU"))
                                pt.add(options, button.builder("save")
                                    :with_text("Save")
                                    :handle_select("set_options")
                                    :advance_to("MAIN_MENU"))
                                return options
                            end))

                        return children
                    end
                )
            ):with_initial_data(function(_services: GameMenuContext, _session_data: MenuContext): {string: any}
                return {
                    log_level = DYNAMIC_CONFIG.log_level,
                    draw_flexbox_debug = DYNAMIC_CONFIG.draw_flexbox_debug,
                    draw_target_debug = DYNAMIC_CONFIG.draw_target_debug,
                    profile = DYNAMIC_CONFIG.profile,
                    head_scale = DYNAMIC_CONFIG.head_scale,
                    dialogue_speed = DYNAMIC_CONFIG.dialogue_speed,
                }
            end),
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

