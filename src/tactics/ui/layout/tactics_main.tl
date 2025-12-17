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

local battle_summary = BattleSummary.new()
local tactics_map = TacticsMap.new(CONFIG.MAP_WIDTH, CONFIG.MAP_HEIGHT,
        {
            decoration_padding = 2,
            decoration = "border",
            internal_margin = { t = 5, b = 5, l = 4, r = 4 }
        })

local left = Box.new({ dir="col", flex_grow = 1, padding = 2})
left:add(battle_summary)
left:add(UnitInfo.new({ padding = 2, decoration = "border"  }))
left:add(EventMessageLog.new({ padding = 2, flex_grow = 1, decoration = "border" }))

local root = SplitPages.new(left, tactics_map)

return { root = root }
