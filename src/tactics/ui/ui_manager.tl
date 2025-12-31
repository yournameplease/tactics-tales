require("src/tactics/ui/types")
local UILayoutId = require("src/tactics/ui/types").UILayoutId
require("src/tactics/config")
local draw_target_manager = require("src/tactics/draw/draw_target_manager")

require("src/tactics/ui/box")

require("src/tactics/ui/validator")

require("profiler")

local tactics_main = require("src/tactics/ui/layout/tactics_main")
local combat_preview = require("src/tactics/ui/layout/combat_preview")
local story_page = require("src/tactics/ui/layout/story_page")
local title_screen = require("src/tactics/ui/layout/title_screen")
local main_menu = require("src/tactics/ui/layout/main_menu")
local chapter_select = require("src/tactics/ui/layout/chapter_select")
local options_menu = require("src/tactics/ui/layout/options_menu")
global record UILayout
    root: UIElement
end

global record UIManager
    is GameService
    where self.id == "ui_manager"
    layouts: { UILayoutId: UILayout }
    current_layout: UILayout
    theme: UITheme
    draw_target_manager: draw_target_manager.DrawTargetManager
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
    self.layouts["CHAPTER_SELECT_PAGE"] = chapter_select
    self.layouts["OPTIONS_MENU_PAGE"] = options_menu

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
        COLOR_TRIM = 9,
        COLOR_PAGE_DECOR = 24,
        COLOR_CLEAR = 20
    }

    self.draw_target_manager = draw_target_manager.new()
    
    return self
end

function UIManager:draw(battle_context: UIContextManager)
    self.current_layout = self.layouts[battle_context.layout]

    local root = self.current_layout.root
    -- Recalculate size and positions

    profile("ui_manager_measure")
    root:measure()
    profile("ui_manager_measure")
    profile("ui_manager_layout")
    root:layout(root.x, root.y)
    profile("ui_manager_layout")

    -- Render
    pt.cls(self.theme.COLOR_CLEAR)
    profile("ui_manager_draw")
    root:draw(battle_context, self.draw_target_manager, self.theme)
    profile("ui_manager_draw")
end

return UIManager
