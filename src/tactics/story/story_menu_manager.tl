require("src/tactics/debug")
require("src/tactics/types")
require("src/tactics/menu/types")
require("src/tactics/menu/menu_manager")
require("src/tactics/joypad")
require("src/tactics/story/story_page")
require("src/tactics/systems/service")
require("src/tactics/menu/menu_manager")
require("src/tactics/story/story_context")
require("src/tactics/menu/cursor/list_cursor")



global record StoryMenuManager
    is MenuManager<StoryContext>
end

local MENU_DATA: { MenuId: MenuDefinition<StoryContext> } = {
    ["MENU_STORY_TEXT"] = {
        initial_step = "ADVANCE_TEXT",
        steps = {
            ["ADVANCE_TEXT"] = ListMenuDefinition.new({
                get_options = function(msb: StoryContext, ctx: MenuContext): {MenuOption}
                    local options: {MenuOption} = {}

                    pt.add(options, {
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

