---@brief
--- Defines the UI layout for various game UIs

local nested_list = require("src.tactics.menu.cursor.nested.list")
local book = require("src.tactics.ui.decoration.book")
local menu = require("src.tactics.ui.components.menu")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local UILayoutId = require("src.tactics.ui.types").UILayoutId
local layout = require("src.tactics.ui.layout")

local layouts: { UILayoutId: layout.UILayout }  = {}

local left = book.flex_page()

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


