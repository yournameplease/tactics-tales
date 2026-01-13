local menu_types = require("src/tactics/menu/types")
local MenuContext = require ("src/tactics/menu/menu_context").MenuContext
local menu_manager = require("src/tactics/menu/menu_manager")
local event_bus = require("src/tactics/systems/event_bus")
local GameMenuContext = require("src/tactics/game/game_menu_context").GameMenuContext
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")
local button_advance_cursor = require("src/tactics/menu/cursor/button_advance_cursor")

local record GameMenuManager
    is menu_manager.MenuManager<GameMenuContext>
end

local game_menu_manager = {
    GameMenuManager = GameMenuManager
}

local MENU_DATA: { menu_types.MenuId: menu_manager.MenuDefinition<GameMenuContext> } = {
    ["MENU_MAIN_MENU"] = {
        initial_step = "TITLE_SCREEN",
        -- initial_step = "MAIN_MENU",
        steps = {
            ["TITLE_SCREEN"] = button_advance_cursor.definition({
                next_state = "MAIN_MENU",
            }),
            ["MAIN_MENU"] = list_cursor.definition({
                get_options = function(_msb: GameMenuContext, _ctx: MenuContext): {list_cursor.ListMenuOption<string>}
                    local options: {list_cursor.ListMenuOption<string>} = {}

                    pt.add(options, {
                        text = "Play",
                        send_command = "GAME_BEGIN_STORY",
                    })
                    pt.add(options, {
                        text = "Chapter Select",
                        next_state = "CHAPTER_SELECT",
                    })
                    pt.add(options, {
                        text = "Options",
                        next_state = "OPTIONS_MENU",
                    })

                    return options
                end
            }),
            ["CHAPTER_SELECT"] = list_cursor.definition({
                set_selected_context = function(s: list_cursor.ListMenuCursor<GameMenuContext, string>, _msb: GameMenuContext, ctx: MenuContext)
                    ctx.story = {
                        id = s.options[s.i].text,
                    }
                end,
                get_options = function(msb: GameMenuContext, _ctx: MenuContext): {list_cursor.ListMenuOption<string>}
                    local options: {list_cursor.ListMenuOption<string>} = {}

                    for _, id in ipairs(msb.story_ids) do
                        pt.add(options, {
                            text = id,
                            send_command = "GAME_BEGIN_STORY",
                        })
                    end

                    return options
                end
            }),
            ["OPTIONS_MENU"] = multiple_options_cursor.definition({
                primary_direction = "vertical",
                wrap = false,
                send_command = "GAME_SET_OPTIONS",
                options = {
                    multiple_options_cursor.option_definition({
                        text = "Log Level",
                        definition = list_cursor.static_definition(
                            {"ERROR", "WARNING", "INFO", "DEBUG", "TRACE"},
                            "log_level",
                            "horizontal"
                        ),
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Draw Flexbox Debug",
                        definition = list_cursor.boolean_yes_no(
                            "draw_flexbox_debug",
                            "horizontal"
                        )
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Draw Target Debug",
                        definition = list_cursor.boolean_yes_no(
                            "draw_target_debug",
                            "horizontal"
                        )
                    }),
                },
            }),
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

