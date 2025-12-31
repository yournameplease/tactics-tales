require("src/tactics/systems/service")
require("src/tactics/ui/types")

require("src/tactics/config")

require("src/tactics/ui/box")
local text_node = require("src/tactics/ui/components/text_node")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local VerticalListMenu = require("src/tactics/ui/panels/vertical_list_menu")
local GameMenuContext = require("src/tactics/game/game_menu_context").GameMenuContext

local SplitPages = require("src/tactics/ui/panels/split_pages")

local left = Box.new({ dir="col", flex_grow = 1, padding = 2})
local right = Box.new({ dir = "col", flex_grow = 1, padding = 2})
right:add(text_node.title( { text = {"Main Menu"} } ))
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
