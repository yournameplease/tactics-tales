require("src/debug")
require("src/types")
require("src/menu/types")
require("src/menu/menu_manager")
require("src/joypad")
require("src/story/story_page_state")
require("src/systems/service")
require("src/menu/menu_manager")


local record StoryMenuServiceBundle
    is MenuServiceBundle
    story_page_state: StoryPageState
end

global record StoryMenuManager
    is TransientGameService, MenuManager<StoryMenuServiceBundle>
    where self.id == 'story_menu_manager'

end

local MENU_DATA: { MenuId: MenuDefinition } = {
    ["MENU_STORY_TEXT"] = {
        initial_step = "ADVANCE_TEXT",
        steps = {
            ["ADVANCE_TEXT"] = ListMenuDefinition.new({
                get_options = function(msb: StoryMenuServiceBundle, ctx: MenuContext): {MenuOption}
                    local options: {MenuOption} = {}

                    add(options, {
                        text = "Continue",
                        send_command = "STORY_ADVANCE_TEXT"
                    })

                    return options
                end
            }),
        }
    }
}

function StoryMenuManager.new(): StoryMenuManager
    return BaseMenuManager.new(
        "story_menu_manager",
        {
            "story_page_state"
        },
        MENU_DATA,
        function(services: { ServiceId: GameService }): StoryMenuServiceBundle
            return {
                story_page_state = services.story_page_state as StoryPageState,
            }
        end
    ) as StoryMenuManager
end

return StoryMenuManager

