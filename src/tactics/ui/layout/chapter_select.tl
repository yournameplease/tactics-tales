local box = require("src/tactics/ui/box")
local text_node = require("src/tactics/ui/components/text_node")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local VerticalListMenu = require("src/tactics/ui/panels/vertical_list_menu")
local GameMenuContext = require("src/tactics/game/game_menu_context").GameMenuContext
local UIContextManager = require("src/tactics/ui/ui_context_manager").UIContextManager

local SplitPages = require("src/tactics/ui/panels/split_pages")

local left = box.new({ dir="col", flex_grow = 1, padding = 2})
local right = box.new({ dir = "col", flex_grow = 1, padding = 2})
right:add(text_node.title( { text = {"Chapters"} } ))
right:add(VerticalListMenu.new(
	"{text}",
	">{text}<",
	function (state: UIContextManager): list_cursor.ListMenuCursor<GameMenuContext, string>
		local cursor = state.game_context.menu_manager.menu_cursor
		assert(cursor is list_cursor.ListMenuCursor<GameMenuContext, string>) 
		return cursor
	end,
	{flex_grow = 1} ))



local root = SplitPages.new(left, right)

return { root = root }
