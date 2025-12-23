
require("src/tactics/debug")
require("src/tactics/types")
require("src/tactics/menu/types")
require("src/tactics/menu/menu_manager")
require("src/tactics/joypad")
require("src/tactics/story/story_page")
require("src/tactics/systems/service")
require("src/tactics/menu/menu_manager")
require("src/tactics/story/story_context")
local GameMenuContext = require("src/tactics/game/base_game_context").GameMenuContext
require("src/tactics/menu/cursor/list_cursor")
require("src/tactics/menu/cursor/multiple_options_cursor")
require("src/tactics/menu/cursor/button_advance_cursor")
local story_types = require("src/tactics/story/types")

global record GameMenuManager
    is MenuManager<GameMenuContext>
end

local MENU_DATA: { MenuId: MenuDefinition<GameMenuContext> } = {
    ["MENU_MAIN_MENU"] = {
        initial_step = "TITLE_SCREEN",
        -- initial_step = "MAIN_MENU",
        steps = {
            ["TITLE_SCREEN"] = ButtonAdvanceMenuDefinition.new({
                next_state = "MAIN_MENU",
            }),
            ["MAIN_MENU"] = ListMenuDefinition.new({
                get_options = function(_msb: GameMenuContext, _ctx: MenuContext): {MenuOption}
                    local options: {MenuOption} = {}

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
            ["CHAPTER_SELECT"] = ListMenuDefinition.new({
                set_selected_context = function(s: ListMenuCursor<GameMenuContext>, _msb: GameMenuContext, ctx: MenuContext)
                    ctx.story = {
                        id = s.options[s.i].text,
                    }
                end,
                get_options = function(msb: GameMenuContext, _ctx: MenuContext): {MenuOption}
                    local options: {MenuOption} = {}

                    for _, id in ipairs(msb.story_ids) do
                        pt.add(options, {
                            text = id,
                            send_command = "GAME_BEGIN_STORY",
                        })
                    end

                    return options
                end
            }),
            ["OPTIONS_MENU"] = MultipleOptionsMenuDefinition.new({
                primary_direction = "vertical",
                wrap = false,
                send_command = "GAME_SET_OPTIONS",
                options = {
                    MenuMultipleOptionDefinition.new({
                        text = "Log Level",
                        definition = ListMenuDefinition.of_static_options(
                            {"ERROR", "WARNING", "INFO", "DEBUG", "TRACE"},
                            "log_level",
                            "horizontal"
                        ),
                    }),
                    MenuMultipleOptionDefinition.new({
                        text = "Draw Flexbox Debug",
                        definition = ListMenuDefinition.of_static_options(
                            {"NO", "YES"},
                            "draw_flexbox_debug",
                            "horizontal"
                        )
                    }),
                },
            }),
        }
    }

}

function GameMenuManager.new(ctx: GameMenuContext, event_bus: EventBus): GameMenuManager
    return BaseMenuManager.new(
        MENU_DATA,
        ctx,
        event_bus
    ) as GameMenuManager
end

return GameMenuManager

