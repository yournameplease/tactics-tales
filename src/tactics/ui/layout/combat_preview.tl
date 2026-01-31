require("src.tactics.config")

local tactics_map = require("src.tactics.ui.panels.tactics_map")
local box = require("src.tactics.ui.box")
local combat_preview = require("src.tactics.ui.panels.combat_preview")
local control_hints = require("src.tactics.ui.panels.control_hints")

local SplitPages = require("src.tactics.ui.panels.split_pages")
local BattleSummary = require("src.tactics.ui.panels.battle_summary")

local battle_summary = BattleSummary.new()
local map = tactics_map.new(
	STATIC_CONFIG.MAP_WIDTH,
	STATIC_CONFIG.MAP_HEIGHT,
        {
            decoration_padding = 2,
            decoration = "border",
            internal_margin = { t = 5, b = 5, l = 4, r = 4 }
        })
local left = box.new({ dir="col", flex_grow = 1, padding = 2})
left:add(battle_summary)
left:add(combat_preview.new({ padding = 2 }))
left:add(box.spacer(1))
left:add(control_hints.new())

local root = SplitPages.new(left, map)

return { root = root }
