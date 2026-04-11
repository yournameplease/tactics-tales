---@brief
--- Defines the UI layout for various game UIs

local book = require("src.tactics.ui.decoration.book")
local menu = require("src.tactics.ui.components.menu")
local box = require("src.tactics.ui.box")
local control_hints = require("src.tactics.ui.panels.control_hints")

---@type table<UILayoutId, UILayout>
local layouts = {}

local left = book.flex_page()
left:add(box.spacer(1))
left:add(control_hints.new(
    ---@param s UIContextManager
    function(s)
        return s.game_context.menu_manager.menu_step
    end,
    {}
))

local content = menu.generic_menu_box(
    ---@param state UIContextManager
    function(state)
        return state.game_context.menu_manager.revision_count
    end,
    ---@param state UIContextManager
    function(state)
        local root_node = state.game_context.menu_manager.menu_step.node
        local node = root_node
        assert(node)
        return node
    end)
local right = book.titled_page(content)

layouts["TITLED_MENU_PAGE"] = {
    root = book.split_pages(left, right),
    modals = {},
}

return layouts
