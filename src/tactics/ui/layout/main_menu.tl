---@brief
--- Defines the UI layout for the main menu screen.

require("src.tactics.config")

local box = require("src.tactics.ui.box")
local text_node = require("src.tactics.ui.components.text_node")
local nested_list = require("src.tactics.menu.cursor.nested.list")
local VerticalButtonList = require("src.tactics.ui.panels.vertical_list_menu")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager

local SplitPages = require("src.tactics.ui.panels.split_pages")

local left = box.new({ dir="col", flex_grow = 1, padding = 2})
local right = box.new({ dir = "col", flex_grow = 1, padding = 2})
right:add(text_node.title( { text = {"Main Menu"} } ))
right:add(VerticalButtonList.new(
	"{text}",
	">{text}<",
	function (state: UIContextManager): nested_list.NestedMenuNode
		local root_node = state.game_context.menu_manager.menu_step.node
		local node = root_node
		assert(node is nested_list.NestedMenuNode) 
		return node
	end,
	{flex_grow = 1}
))



local root = SplitPages.new(left, right)

return { root = root }
