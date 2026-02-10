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
local ButtonCursor = button.ButtonCursor
local selection = require("src.tactics.menu.cursor.selection")
local SelectionDefinition = selection.SelectionMenuDefinition
local SelectionCursor = selection.SelectionMenuNode
local story = require("src.tactics.story.types")
local StoryId = story.StoryId

local record GameMenuManager
    is menu_manager.MenuManager
end

local game_menu_manager = {
    GameMenuManager = GameMenuManager
}


local function handle_begin_story(self: ButtonCursor, game_ctx: GameMenuContext, menu_ctx: GameMainMenuContext)
    local story_id = self.value as StoryId
    game_ctx.handle_begin_story(story_id)
end

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition } = {
    ["MENU_MAIN_MENU"] = {
        initial_step = "TITLE_SCREEN",
        steps = {
            ["TITLE_SCREEN"] = step_definition.of_node(
                button.builder()
                :with_text("Main Menu")
                :advance_to("MAIN_MENU")
            ),
            ["MAIN_MENU"] = step_definition.of_node(
                list.column(
                    function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}

                        pt.add(options, button.builder()
                            :with_text("Play")
                            :handle_select(handle_begin_story))
                        pt.add(options, button.builder()
                            :with_text("Chapter Select")
                            :advance_to("CHAPTER_SELECT"))
                        pt.add(options, button.builder()
                            :with_text("Options")
                            :advance_to("OPTIONS_MENU"))

                        return options
                    end
                )
            ),
            ["CHAPTER_SELECT"] = step_definition.of_node(
                list.column(
                    function(msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {ButtonDefinition} = {}

                        for _,story_id in ipairs(msb.story_ids) do
                            pt.add(options, button.builder()
                                :with_text(story_id)
                                :with_value(story_id)
                                :handle_select(handle_begin_story))
                        end

                        return options
                    end
                )
            ),
            ["OPTIONS_MENU"] = step_definition.of_node(
                list.column(
                    function(_msb: GameMenuContext, _ctx: MenuContext): {MenuNodeDefinition}
                        local options: {MenuNodeDefinition} = {}

                        pt.add(options, selection.row()
                            :with_label("Log Level")
                            :with_key("log_level")
                            :with_static_options({"ERROR", "WARNING", "INFO", "DEBUG", "TRACE"}))
                        pt.add(options, selection.row()
                            :with_label("Draw Flexbox Debug")
                            :with_key("draw_flexbox_debug")
                            :with_yes_no_options())
                        pt.add(options, selection.row()
                            :with_label("Draw Target Debug")
                            :with_key("draw_target_debug")
                            :with_yes_no_options())
                        pt.add(options, selection.row()
                            :with_label("Profiler")
                            :with_key("profile")
                            :with_yes_no_options())
                        pt.add(options, selection.row()
                            :with_label("Head Scale")
                            :with_key("head_scale")
                            :with_static_options({1, 2, 3, 4}))
                        pt.add(options, selection.row()
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

                        -- TODO: back/reset/save
                        -- pt.add(options, list.row()
                        -- select_handler = function(_self: multiple_options_cursor.MultipleOptionsMenuNode, game_ctx: GameMenuContext, menu_ctx: GameMainMenuContext)
                        --     game_ctx.handle_set_config(
                        --         menu_ctx.metadata as DynamicConfig
                        --     )
                        -- end,

                        return options
                    end
                )
            ),
        }
    }

}

function game_menu_manager.new(ctx: GameMenuContext, bus: event_bus.EventBus): GameMenuManager
    return menu_manager.new(
        MENU_DATA,
        ctx,
        bus
    ) as GameMenuManager
end

return game_menu_manager

