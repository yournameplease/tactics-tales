require("src/systems/service")
require("src/types")
require("src/ui/types")

require("src/battle/battle_context")
require("src/story/story_context")
require("src/config")

require("src/ui/panels/tactics_map")
require("src/ui/box")
require("src/ui/panels/unit_info")
require("src/ui/panels/combat_preview")
require("src/ui/panels/event_message_log")
local VerticalMultiSelectMenu = require("src/ui/panels/vertical_list_multi_select")

local SplitPages = require("src/ui/panels/split_pages")

require("src/ui/validator")


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

