local menu_types = require("src/tactics/menu/types")
local MenuContext = require ("src/tactics/menu/menu_context").MenuContext
local menu_manager = require("src/tactics/menu/menu_manager")
local event_bus = require("src/tactics/systems/event_bus")
local GameMenuContext = require("src/tactics/game/game_menu_context").GameMenuContext
local GameMainMenuContext = require("src/tactics/menu/menu_context").GameMainMenuContext
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")

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
            ["TITLE_SCREEN"] = list_cursor.definition({
                get_options = function(_msb: GameMenuContext, _ctx: MenuContext): {list_cursor.ListMenuOption<GameMenuContext, string>}
                    return {{
                        text = "Main Menu",
                        next_state = "MAIN_MENU",
                    }}
                end
            }),
            ["MAIN_MENU"] = list_cursor.definition({
                get_options = function(_msb: GameMenuContext, _ctx: MenuContext): {list_cursor.ListMenuOption<GameMenuContext, string>}
                    local options: {list_cursor.ListMenuOption<GameMenuContext, string>} = {}

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
                set_selected_context = function(s: list_cursor.ListMenuCursor<GameMenuContext, string>, game_ctx: GameMenuContext, menu_ctx: GameMainMenuContext)
                    menu_ctx.story = {
                        id = s.options[s.i].text,
                    }
                end,
                get_options = function(msb: GameMenuContext, _ctx: MenuContext): {list_cursor.ListMenuOption<GameMenuContext, string>}
                    local options: {list_cursor.ListMenuOption<GameMenuContext, string>} = {}

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
                select_handler = function(self: multiple_options_cursor.MultipleOptionsMenuCursor<GameMenuContext>, game_ctx: GameMenuContext, menu_ctx: GameMainMenuContext)
                    game_ctx.handle_set_config(
                        menu_ctx.metadata as DynamicConfig
                    )
                end,
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
                    multiple_options_cursor.option_definition({
                        text = "Head Scale",
                        definition = list_cursor.static_definition(
                            {1, 2, 3, 4},
                            "head_scale",
                            "horizontal"
                        )
                    }),
                    multiple_options_cursor.option_definition({
                        text = "Text Speed",
                        definition = list_cursor.static_definition(
                            {
                            	"very_slow",
                            	"slow",
                            	"normal",
                            	"fast",
                            	"very_fast",
                            	"instant",
                            },
                            "dialogue_speed",
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

