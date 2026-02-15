---@brief
--- The main UI manager, responsible for calculating layouts and drawing
--- the current UI based on the active layout and context.

require("src.tactics.config")
require("profiler")

local maps = require("src.tactics.util.maps")
local UILayoutId = require("src.tactics.ui.types").UILayoutId
local UILayout = require("src.tactics.ui.layout").UILayout
local draw_target_manager = require("src.tactics.draw.draw_target_manager")
local box = require("src.tactics.ui.box")
local menu_validator = require("src.tactics.ui.validator")
local MenuMouseSelection = require("src.tactics.menu.menu_cursor").mouse_selection.MenuMouseSelection
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local tactics_main = require("src.tactics.ui.layout.tactics_main")
local story_page = require("src.tactics.ui.layout.story_page")
local title_screen = require("src.tactics.ui.layout.title_screen")
local main_menu = require("src.tactics.ui.layout.main_menu")
local chapter_select = require("src.tactics.ui.layout.chapter_select")
local options_menu = require("src.tactics.ui.layout.options_menu")

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

    maps.add_all(self.layouts, tactics_main)
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
    local modals = self.current_layout.modals

    if modals ~= nil then
        for _,modal in ipairs(self.current_layout.modals) do
            if modal.node.modal.active then
                local modal_hit = box.find_topmost_selection(modal.node, mx, my)
                if modal_hit then
                    return modal_hit
                end
            end
        end 
    end
    
    local root = self.current_layout.root
    
    return box.find_topmost_selection(root, mx, my)
end

function UIManager:calculate(ui_ctx: UIContextManager)
    profile("ui_manager_calculate")
    self.current_layout = self.layouts[ui_ctx.layout]

    local root = self.current_layout.root
    
    -- Recalculate size and positions
    root:recalculate(1, 0, 0, 480, 270, ui_ctx)
    if self.current_layout.modals then
        for _,modal in ipairs(self.current_layout.modals) do
            modal.node:recalculate_modal(ui_ctx, root)
        end 
    end
    profile("ui_manager_calculate")
end

function UIManager:draw(ui_ctx: UIContextManager)
    local root = self.current_layout.root
    -- Render
    profile("ui_manager_draw")
    pt.cls(self.theme.COLOR_CLEAR)
    root:draw(ui_ctx, self.draw_target_manager, self.theme)
    if self.current_layout.modals then
        for _,modal in ipairs(self.current_layout.modals) do
            modal.node:draw_modal(ui_ctx, self.draw_target_manager, self.theme)
        end 
    end
    profile("ui_manager_draw")
end

return ui_manager
