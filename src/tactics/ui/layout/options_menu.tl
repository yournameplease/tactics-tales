---@brief
--- Defines the UI layout for the options menu screen.

local text_node = require("src.tactics.ui.components.text_node")
local box = require("src.tactics.ui.box")
local multiple_options_cursor = require("src.tactics.menu.cursor.multiple_options_cursor")
local VerticalMultiSelectMenu = require("src.tactics.ui.panels.vertical_list_multi_select")
local GameMenuContext = require("src.tactics.game.game_menu_context").GameMenuContext
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager

local SplitPages = require("src.tactics.ui.panels.split_pages")

local left = box.new({ dir="col", flex_grow = 1, padding = 2})
local right = box.new({ dir = "col", flex_grow = 1, padding = 2})
right:add(text_node.title( { text = {"Main Menu"} } ))
right:add(VerticalMultiSelectMenu.new(
	"{label}: {value}",
	"{label}: "..pt.chr(139).."{value}"..pt.chr(145),
	function (state: UIContextManager): multiple_options_cursor.MultipleOptionsMenuCursor<GameMenuContext>
		local cursor = state.game_context.menu_manager.menu_cursor
		assert(cursor is multiple_options_cursor.MultipleOptionsMenuCursor<GameMenuContext>) 
		return cursor
	end,
	{flex_grow = 1} ))



local root = SplitPages.new(left, right)

return { root = root }

