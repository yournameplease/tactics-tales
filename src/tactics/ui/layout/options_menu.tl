---@brief
--- Defines the UI layout for the options menu screen.

local text_node = require("src.tactics.ui.components.text_node")
local box = require("src.tactics.ui.box")
local generic_menu_box = require("src.tactics.ui.panels.generic_list_menu")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNode = menu_cursor.MenuNode

local SplitPages = require("src.tactics.ui.panels.split_pages")

local left = box.new({ dir="col", flex_grow = 1, padding = 2})
local right = box.new({ dir = "col", flex_grow = 1, padding = 2})
right:add(text_node.title( { text = {"Options"} } ))
right:add(generic_menu_box.new(
	"{label}: {value}",
	"{label}: >{value}<",
	function (state: UIContextManager): MenuNode
		local root_node = state.game_context.menu_manager.menu_step.node
		local node = root_node
		return node
	end,
	{flex_grow = 1} ))
right:add(box.spacer(1))


local root = SplitPages.new(left, right)

return { root = root }

