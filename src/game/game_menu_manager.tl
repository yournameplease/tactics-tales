
require("src/debug")
require("src/types")
require("src/menu/types")
require("src/menu/menu_manager")
require("src/joypad")
require("src/story/story_page")
require("src/systems/service")
require("src/menu/menu_manager")
require("src/story/story_context")
require("src/game/base_game_context")
require("src/menu/cursor/list_cursor")
require("src/menu/cursor/multiple_options_cursor")
require("src/menu/cursor/button_advance_cursor")


global record GameMenuManager
    is MenuManager<BaseGameContext>
end

local MENU_DATA: { MenuId: MenuDefinition<BaseGameContext> } = {
    ["MENU_MAIN_MENU"] = {
        initial_step = "TITLE_SCREEN",
        -- initial_step = "MAIN_MENU",
        steps = {
            ["TITLE_SCREEN"] = ButtonAdvanceMenuDefinition.new({
                next_state = "MAIN_MENU",
            }),
            ["MAIN_MENU"] = ListMenuDefinition.new({
                get_options = function(msb: BaseGameContext, ctx: MenuContext): {MenuOption}
                    local options: {MenuOption} = {}

                    add(options, {
                        text = "Play",
                        send_command = "GAME_BEGIN_STORY",
                    })
                    add(options, {
                        text = "Options",
                        next_state = "OPTIONS_MENU",
                    })

                    return options
                end
            }),
            -- ["OPTIONS_MENU"] = MultipleOptionsMenuDefinition.new({
            --     get_options = function(msb: BaseGameContext, ctx: MenuContext): {MenuOption}
            --         local options: {MenuOption} = {}

            --         add(options, {
            --             text = "Play",
            --             send_command = "GAME_BEGIN_STORY",
            --         })
            --         add(options, {
            --             text = "Options",
            --             next_state = "OPTIONS_MENU",
            --         })

            --         return options
            --     end
            -- }),
        }
    }

}

function GameMenuManager.new(ctx: BaseGameContext): GameMenuManager
    return BaseMenuManager.new(
        MENU_DATA,
        ctx
    ) as GameMenuManager
end

return GameMenuManager

