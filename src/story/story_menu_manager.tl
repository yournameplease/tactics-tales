require("src/debug")
require("src/types")
require("src/menu/types")
require("src/menu/menu_manager")
require("src/joypad")
require("src/story/story_page")
require("src/systems/service")
require("src/menu/menu_manager")
require("src/story/story_context")
require("src/menu/cursor/list_cursor")



global record StoryMenuManager
    is TransientGameService, MenuManager<StoryContext>
    where self.id == 'story_menu_manager'

end

local MENU_DATA: { MenuId: MenuDefinition<StoryContext> } = {
    ["MENU_STORY_TEXT"] = {
        initial_step = "ADVANCE_TEXT",
        steps = {
            ["ADVANCE_TEXT"] = ListMenuDefinition.new({
                get_options = function(msb: StoryContext, ctx: MenuContext): {MenuOption}
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

function StoryMenuManager.new(ctx: StoryContext): StoryMenuManager
    return BaseMenuManager.new(
        MENU_DATA,
        ctx
    ) as StoryMenuManager
end

return StoryMenuManager

