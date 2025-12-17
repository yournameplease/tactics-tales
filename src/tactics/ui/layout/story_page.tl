require("src/tactics/systems/service")
require("src/tactics/types")
require("src/tactics/ui/types")

require("src/tactics/battle/battle_context")
require("src/tactics/story/story_context")
require("src/tactics/story/story_page")
require("src/tactics/config")

require("src/tactics/ui/panels/tactics_map")
require("src/tactics/ui/box")
require("src/tactics/ui/panels/unit_info")
require("src/tactics/ui/panels/combat_preview")
require("src/tactics/ui/panels/event_message_log")

local SplitPages = require("src/tactics/ui/panels/split_pages")

require("src/tactics/ui/validator")

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
