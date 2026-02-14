---@brief
--- Defines the UI layout for the main menu screen.

require("src.tactics.config")

local text_node = require("src.tactics.ui.components.text_node")
local nested_list = require("src.tactics.menu.cursor.nested.list")
local book = require("src.tactics.ui.decoration.book")
local menu = require("src.tactics.ui.components.menu")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager

local left = book.flex_page()
local right = book.flex_page()
right:add(text_node.title( { content = {"Main Menu"} } ))
right:add(menu.generic_menu_box(
	function (state: UIContextManager): integer
		return state.game_context.menu_manager.revision_count
	end,
	function (state: UIContextManager): nested_list.NestedMenuNode
		local root_node = state.game_context.menu_manager.menu_step.node
		local node = root_node
		assert(node is nested_list.NestedMenuNode) 
		return node
	end))

local root = book.split_pages(left, right)

return { root = root }
