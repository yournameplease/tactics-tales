require("src/systems/service")
require("src/types")
require("src/ui/types")

require("src/config")

require("src/ui/box")

require("src/ui/validator")

local tactics_main = require("src/ui/layout/tactics_main")
local combat_preview = require("src/ui/layout/combat_preview")
local story_page = require("src/ui/layout/story_page")
local title_screen = require("src/ui/layout/title_screen")
local main_menu = require("src/ui/layout/main_menu")
global record UILayout
    root: UIElement
end

global record UIManager
    is GameService
    where self.id == "ui_manager"
    layouts: { UILayoutId: UILayout }
    current_layout: UILayout
    theme: UITheme
end

function UIManager:init(_service_manager: ServiceManager, _services: { ServiceId: GameService })

end

-- Define Layouts
function UIManager.new(): UIManager

    local self: UIManager = setmetatable({
        id = "ui_manager",
        dependencies = {},
    }, { __index = UIManager }) 
    -- 1. Create the BATTLE layout tree
    self.layouts = {}

    self.layouts["TACTICS"] = tactics_main
    self.layouts["COMBAT_PREVIEW"] = combat_preview
    self.layouts["STORY_PAGE"] = story_page
    self.layouts["TITLE_SCREEN"] = title_screen
    self.layouts["MAIN_MENU_PAGE"] = main_menu

    -- Validate all layouts
    for id, v in pairs(self.layouts) do
        MenuValidator.validate(v.root, id)
    end

    -- Set initial
    self.current_layout = self.layouts.TACTICS

    -- old "stone" theme
    -- self.theme = {
    --     COLOR_DECORATION_PRIMARY = 22,
    --     COLOR_DECORATION_HIGHLIGHT = 6,
    --     COLOR_DECORATION_SHADOW = 5,
    --     COLOR_INTERIOR = 21,
    --     COLOR_INTERIOR_TEXT = 7,
    -- }
    self.theme = {
        COLOR_DECORATION_PRIMARY = 4,
        COLOR_DECORATION_HIGHLIGHT = 31,
        COLOR_DECORATION_SHADOW = 20,
        COLOR_INTERIOR = 15,
        COLOR_INTERIOR_TEXT = 21,
        COLOR_CLEAR = 20
    }

    return self
end

function UIManager:draw(battle_context: UIContextManager)
    self.current_layout = self.layouts[battle_context.layout]

    local root = self.current_layout.root
    -- Recalculate size and positions
    root:measure()
    root:layout(root.x, root.y)

    -- Render
    pt.cls(self.theme.COLOR_CLEAR)
    root:draw(battle_context, self.theme)
end

return UIManager
