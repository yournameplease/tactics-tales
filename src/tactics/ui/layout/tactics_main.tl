require("src/tactics/systems/service")
require("src/tactics/ui/types")

require("src/tactics/story/story_menu_context")
require("src/tactics/config")

require("src/tactics/ui/panels/tactics_map")
require("src/tactics/ui/box")
require("src/tactics/ui/panels/unit_info")
require("src/tactics/ui/panels/combat_preview")
require("src/tactics/ui/panels/event_message_log")

local SplitPages = require("src/tactics/ui/panels/split_pages")
local BattleSummary = require("src/tactics/ui/panels/battle_summary")

require("src/tactics/ui/validator")

local battle_summary = BattleSummary.new()
local tactics_map = TacticsMap.new(CONFIG.MAP_WIDTH, CONFIG.MAP_HEIGHT,
        {
            decoration_padding = 2,
            decoration = "border",
            internal_margin = { t = 5, b = 5, l = 4, r = 4 }
        })

local left = Box.new({ dir="col", flex_grow = 1, padding = 2})
left:add(battle_summary)
left:add(UnitInfo.new({ padding = 2 }))
left:add(EventMessageLog.new({ padding = 2, flex_grow = 1, }))

local root = SplitPages.new(left, tactics_map)

return { root = root }
