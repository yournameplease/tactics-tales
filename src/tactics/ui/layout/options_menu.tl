require("src/tactics/systems/service")
require("src/tactics/types")
require("src/tactics/ui/types")

require("src/tactics/config")

require("src/tactics/ui/panels/tactics_map")
require("src/tactics/ui/box")
require("src/tactics/ui/panels/unit_info")
require("src/tactics/ui/panels/combat_preview")
require("src/tactics/ui/panels/event_message_log")
local VerticalMultiSelectMenu = require("src/tactics/ui/panels/vertical_list_multi_select")

local SplitPages = require("src/tactics/ui/panels/split_pages")

require("src/tactics/ui/validator")


local left = Box.new({ dir="col", flex_grow = 1, padding = 2})
local right = Box.new({ dir = "col", flex_grow = 1, padding = 2})
right:add(TextNode.new( { flex_grow = 1, text = {"Main Menu"} } ))
right:add(VerticalMultiSelectMenu.new(
	"{label}: {value}",
	"{label}: "..pt.chr(139).."{value}"..pt.chr(145),
	function (state: UIContextManager): MultipleOptionsMenuCursor<BaseGameContext>
		local cursor = state.game_context.ctx.menu_manager.menu_cursor
		assert(cursor is MultipleOptionsMenuCursor<BaseGameContext>) 
		return cursor
	end,
	{flex_grow = 1} ))



local root = SplitPages.new(left, right)

return { root = root }

