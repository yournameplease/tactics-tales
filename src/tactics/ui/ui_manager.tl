require("src/tactics/config")
require("profiler")

local UILayoutId = require("src/tactics/ui/types").UILayoutId
local draw_target_manager = require("src/tactics/draw/draw_target_manager")
local box = require("src/tactics/ui/box")
local menu_validator = require("src/tactics/ui/validator")
local MenuMouseSelection = require("src/tactics/menu/menu_cursor").mouse_selection.MenuMouseSelection
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager
local tactics_main = require("src/tactics/ui/layout/tactics_main")
local combat_preview = require("src/tactics/ui/layout/combat_preview")
local story_page = require("src/tactics/ui/layout/story_page")
local title_screen = require("src/tactics/ui/layout/title_screen")
local main_menu = require("src/tactics/ui/layout/main_menu")
local chapter_select = require("src/tactics/ui/layout/chapter_select")
local options_menu = require("src/tactics/ui/layout/options_menu")

local record UILayout
    root: box.UIElement
end

local record UIManager
    layouts: { UILayoutId: UILayout }
    current_layout: UILayout
    theme: UITheme
    draw_target_manager: draw_target_manager.DrawTargetManager
end

local ui_manager = {
    UIManager = UIManager
}

function ui_manager.new(): UIManager
    local self: UIManager = setmetatable({}, {
        __index = UIManager
    })
         
    self.layouts = {}

    self.layouts["TACTICS"] = tactics_main
    self.layouts["COMBAT_PREVIEW"] = combat_preview
    self.layouts["STORY_PAGE"] = story_page
    self.layouts["TITLE_SCREEN"] = title_screen
    self.layouts["MAIN_MENU_PAGE"] = main_menu
    self.layouts["CHAPTER_SELECT_PAGE"] = chapter_select
    self.layouts["OPTIONS_MENU_PAGE"] = options_menu

    -- Validate layouts
    for id, v in pairs(self.layouts) do
        menu_validator.validate(v.root, id)
    end

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

function UIManager:get_mouse_selection(mx: number, my: number): MenuMouseSelection 
    local root = self.current_layout.root
    
    return box.find_topmost_selection(root, mx, my)
end

function UIManager:calculate(ui_ctx: UIContextManager)
    self.current_layout = self.layouts[ui_ctx.layout]

    local root = self.current_layout.root
    
    -- Recalculate size and positions
    profile("ui_manager_calculate")
    box.compute_children(root, ui_ctx)
    root:measure(1)
    root:layout(root.x, root.y)
    profile("ui_manager_calculate")
end

function UIManager:draw(ui_ctx: UIContextManager)
    local root = self.current_layout.root
    -- Render
    profile("ui_manager_draw")
    pt.cls(self.theme.COLOR_CLEAR)
    root:draw(ui_ctx, self.draw_target_manager, self.theme)
    profile("ui_manager_draw")
end

return ui_manager
