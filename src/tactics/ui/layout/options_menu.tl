require("src/tactics/systems/service")
require("src/tactics/types")
require("src/tactics/ui/types")

require("src/tactics/config")

local text_node = require("src/tactics/ui/components/text_node")
require("src/tactics/ui/panels/tactics_map")
require("src/tactics/ui/box")
require("src/tactics/ui/panels/unit_info")
require("src/tactics/ui/panels/combat_preview")
require("src/tactics/ui/panels/event_message_log")
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")
local VerticalMultiSelectMenu = require("src/tactics/ui/panels/vertical_list_multi_select")
local GameMenuContext = require("src/tactics/game/base_game_context").GameMenuContext

local SplitPages = require("src/tactics/ui/panels/split_pages")

require("src/tactics/ui/validator")


local left = Box.new({ dir="col", flex_grow = 1, padding = 2})
local right = Box.new({ dir = "col", flex_grow = 1, padding = 2})
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

