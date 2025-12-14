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

local SplitPages = require("src/ui/panels/split_pages")

require("src/ui/validator")


local left = Box.new({ dir="col", flex_grow = 1, padding = 2})
local root = SplitPages.new(left, left)

return { root = root }
