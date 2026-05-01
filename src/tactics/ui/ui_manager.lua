---@brief
--- The main UI manager, responsible for calculating layouts and drawing
--- the current UI based on the active layout and context.

local maps = require("src.tactics.util.maps")
local draw_target_manager = require("src.tactics.draw.draw_target_manager")
local box = require("src.tactics.ui.box")
local menu_validator = require("src.tactics.ui.validator")
local tactics_layouts = require("src.tactics.ui.layout.tactics")
local game_layouts = require("src.tactics.ui.layout.game")
local campaign_page = require("src.tactics.ui.layout.campaign_page")
local title_screen = require("src.tactics.ui.layout.title_screen")

---@class UIManager
---@field layouts table<UILayoutId, UILayout> Map of layout ID to layout definition.
---@field current_layout UILayout The currently active layout.
---@field current_layout_id UILayoutId The ID of the currently active layout.
---@field theme UITheme Color definitions for rendering.
---@field draw_target_manager DrawTargetManager
local UIManager = {}
UIManager.__index = UIManager

local ui_manager = {
    UIManager = UIManager
}

--- Construct a new UIManager, registering all layouts and initialising the theme.
---@return UIManager
function ui_manager.new()
    ---@type UIManager
    local self = setmetatable({}, UIManager)

    self.layouts = {}

    maps.add_all(self.layouts, tactics_layouts)
    maps.add_all(self.layouts, game_layouts)
    self.layouts["CAMPAIGN_PAGE"] = campaign_page
    self.layouts["TITLE_SCREEN"] = title_screen

    -- Validate layouts
    for id, v in pairs(self.layouts) do
        menu_validator.validate(v.root, id)
    end

    self.current_layout = self.layouts.TACTICS

    self.theme = {
        COLOR_DECORATION_PRIMARY = 4,
        COLOR_DECORATION_HIGHLIGHT = 31,
        COLOR_DECORATION_SHADOW = 20,
        COLOR_INTERIOR = 15,
        COLOR_INTERIOR_TEXT = 21,
        COLOR_TRIM = 9,
        COLOR_PAGE_DECOR = 24,
        COLOR_CLEAR = 20,
        COLOR_SIDE = 16,
        COLOR_HP_BORDER = 21,
        COLOR_HP_SPENT = 15,
    }

    self.draw_target_manager = draw_target_manager.new()

    return self
end

--- Return the topmost selectable element under the given mouse coordinates,
--- checking active modals before the root layout.
---@param mx number
---@param my number
---@return MenuMouseSelection?
function UIManager:get_mouse_selection(mx, my)
    local modals = self.current_layout.modals

    if modals ~= nil then
        for _, modal in ipairs(self.current_layout.modals) do
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

--- Recalculate layout positions and sizes for the current frame.
---@param ui_ctx UIContextManager
function UIManager:calculate(ui_ctx)
    profile("ui_manager_calculate")

    local is_new_layout = self.current_layout_id ~= ui_ctx.layout

    self.current_layout = self.layouts[ui_ctx.layout]
    self.current_layout_id = ui_ctx.layout

    local root = self.current_layout.root

    root:recalculate(1, 0, 0, 480, 270, ui_ctx, is_new_layout)
    if self.current_layout.modals then
        for _, modal in ipairs(self.current_layout.modals) do
            modal.node:recalculate_modal(ui_ctx, root)
        end
    end
    profile("ui_manager_calculate")
end

--- Draw the current layout and any active modals.
---@param ui_ctx UIContextManager
function UIManager:draw(ui_ctx)
    local root = self.current_layout.root
    profile("ui_manager_draw")
    cls(self.theme.COLOR_CLEAR)
    root:draw(ui_ctx, self.draw_target_manager, self.theme)
    if self.current_layout.modals then
        for _, modal in ipairs(self.current_layout.modals) do
            modal.node:draw_modal(ui_ctx, self.draw_target_manager, self.theme)
        end
    end
    profile("ui_manager_draw")
end

return ui_manager
