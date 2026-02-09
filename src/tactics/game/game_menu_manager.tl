---@brief
--- Manages the main game menu, including the title screen,
--- chapter select, and options menus.

local menu_types = require("src.tactics.menu.types")
local MenuContext = require ("src.tactics.menu.menu_context").MenuContext
local menu_manager = require("src.tactics.menu.menu_manager")
local event_bus = require("src.tactics.systems.event_bus")
local GameMenuContext = require("src.tactics.game.game_menu_context").GameMenuContext
local GameMainMenuContext = require("src.tactics.menu.menu_context").GameMainMenuContext
local list_cursor = require("src.tactics.menu.cursor.list_cursor")
local nested_cursor = require("src.tactics.menu.cursor.nested_cursor")
local button = require("src.tactics.menu.cursor.button")
local ButtonDefinition = button.ButtonDefinition
local ButtonCursor = button.ButtonCursor
local multiple_options_cursor = require("src.tactics.menu.cursor.multiple_options_cursor")

local record GameMenuManager
    is menu_manager.MenuManager
end

local game_menu_manager = {
    GameMenuManager = GameMenuManager
}


local function handle_begin_story(self: ButtonCursor, game_ctx: GameMenuContext, menu_ctx: GameMainMenuContext)
    game_ctx.handle_begin_story(self.value)
end

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition } = {
    ["MENU_MAIN_MENU"] = {
        initial_step = "TITLE_SCREEN",
        steps = {
            ["TITLE_SCREEN"] = button.builder()
                :with_text("Main Menu")
                :advance_to("MAIN_MENU"),
            ["MAIN_MENU"] = nested_cursor.column(
                function(_msb: GameMenuContext, _ctx: MenuContext): {ButtonDefinition}
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
            ),
            ["CHAPTER_SELECT"] = nested_cursor.column(
                function(msb: GameMenuContext, _ctx: MenuContext): {ButtonDefinition}
                    local options: {ButtonDefinition} = {}

                    for _, id in ipairs(msb.story_ids) do
                        pt.add(options, button.builder()
                            :with_text(id)
                            :with_value(id)
                            :handle_select(handle_begin_story))
                    end

                    return options
                end
            ),
            -- ["OPTIONS_MENU"] = multiple_options_cursor.definition({
            --     primary_direction = "vertical",
            --     wrap = false,
            --     select_handler = function(_self: multiple_options_cursor.MultipleOptionsMenuCursor, game_ctx: GameMenuContext, menu_ctx: GameMainMenuContext)
            --         game_ctx.handle_set_config(
            --             menu_ctx.metadata as DynamicConfig
            --         )
            --     end,
            --     options = {
            --         multiple_options_cursor.option_definition({
            --             text = "Log Level",
            --             definition = list_cursor.static_definition(
            --                 {"ERROR", "WARNING", "INFO", "DEBUG", "TRACE"},
            --                 "log_level",
            --                 "horizontal"
            --             ),
            --         }),
            --         multiple_options_cursor.option_definition({
            --             text = "Draw Flexbox Debug",
            --             definition = list_cursor.boolean_yes_no(
            --                 "draw_flexbox_debug",
            --                 "horizontal"
            --             )
            --         }),
            --         multiple_options_cursor.option_definition({
            --             text = "Draw Target Debug",
            --             definition = list_cursor.boolean_yes_no(
            --                 "draw_target_debug",
            --                 "horizontal"
            --             )
            --         }),
            --         multiple_options_cursor.option_definition({
            --             text = "Profiler",
            --             definition = list_cursor.boolean_yes_no(
            --                 "profile",
            --                 "horizontal"
            --             )
            --         }),
            --         multiple_options_cursor.option_definition({
            --             text = "Head Scale",
            --             definition = list_cursor.static_definition(
            --                 {1, 2, 3, 4},
            --                 "head_scale",
            --                 "horizontal"
            --             )
            --         }),
            --         multiple_options_cursor.option_definition({
            --             text = "Text Speed",
            --             definition = list_cursor.static_definition(
            --                 {
            --                 	"very_slow",
            --                 	"slow",
            --                 	"normal",
            --                 	"fast",
            --                 	"very_fast",
            --                 	"instant",
            --                 },
            --                 "dialogue_speed",
            --                 "horizontal"
            --             )
            --         }),
            --     },
            -- }),
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

