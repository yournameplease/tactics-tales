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
local BattleSummary = require("src/ui/panels/battle_summary")

require("src/ui/validator")


local root = Box.new({
    x=0, y=0,
    w=480, h=270,
    internal_margin = {t = 4},
    dir="row",
    transparent = true
})

-- Left Sidebar
root:add(Box.new({ dir="col", flex_grow = 1, padding = 2}))

return { root = root }
