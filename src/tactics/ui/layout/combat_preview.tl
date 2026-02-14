---@brief
--- Defines the UI layout for the combat preview screen.

require("src.tactics.config")

local tactics_map = require("src.tactics.ui.panels.tactics_map")
local box = require("src.tactics.ui.box")
local battle = require("src.tactics.ui.panels.battle")
local control_hints = require("src.tactics.ui.panels.control_hints")
local book = require("src.tactics.ui.decoration.book")

local battle_summary = battle.battle_summary()
local map = tactics_map.new(
	STATIC_CONFIG.MAP_WIDTH,
	STATIC_CONFIG.MAP_HEIGHT
)
local left = book.flex_page()
left:add(battle_summary)
left:add(battle.combat_preview())
left:add(box.spacer(1))
left:add(control_hints.new())

local root = book.split_pages(left, map)

return { root = root }
