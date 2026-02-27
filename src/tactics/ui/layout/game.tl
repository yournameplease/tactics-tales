---@brief
--- Defines the UI layout for various game UIs

local nested_list = require("src.tactics.menu.cursor.nested.list")
local book = require("src.tactics.ui.decoration.book")
local menu = require("src.tactics.ui.components.menu")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local UILayoutId = require("src.tactics.ui.types").UILayoutId
local layout = require("src.tactics.ui.layout")
local box = require("src.tactics.ui.box")
local control_hints = require("src.tactics.ui.panels.control_hints")
local menu_manager = require("src.tactics.menu.menu_manager")

local layouts: { UILayoutId: layout.UILayout }  = {}

local left = book.flex_page()
left:add(box.spacer(1))
left:add(control_hints.new(
	function (s: UIContextManager): menu_manager.MenuStep
		return s.game_context.menu_manager.menu_step
	end
))

local content = menu.generic_menu_box(
	function (state: UIContextManager): integer
		return state.game_context.menu_manager.revision_count
	end,
	function (state: UIContextManager): nested_list.NestedMenuNode
		local root_node = state.game_context.menu_manager.menu_step.node
		local node = root_node
		assert(node is nested_list.NestedMenuNode) 
		return node
	end)
local right = book.titled_page(content)

layouts["TITLED_MENU_PAGE"] = {
	root = book.split_pages(left, right),
}

return layouts


