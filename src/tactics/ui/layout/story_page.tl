require("src/systems/service")
require("src/types")
require("src/ui/types")

require("src/battle/battle_context")
require("src/story/story_context")
require("src/story/story_page")
require("src/config")

require("src/ui/panels/tactics_map")
require("src/ui/box")
require("src/ui/panels/unit_info")
require("src/ui/panels/combat_preview")
require("src/ui/panels/event_message_log")

local SplitPages = require("src/ui/panels/split_pages")

require("src/ui/validator")

local left = Box.new({ dir="col", flex_grow = 1, padding = 2})

local story_page = MessageLog.new({
    dir="col",
    flex_grow = 1,
    padding = 2,
    draw_properties = {
        text_direction = "down",
        wrap_mode = "ellipsis",
    },
    func = function(state: UIContextManager, _row_limit: integer): { string }
        return state.story_context.ctx.story_page.text
    end
})

local root = SplitPages.new(left, story_page)

return { root = root }
