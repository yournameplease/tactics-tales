---@brief
--- Defines the main UI layout for the tactical battle screen.

require("src.tactics.config")

local tactics_map = require("src.tactics.ui.panels.tactics_map")
local box = require("src.tactics.ui.box")
local battle = require("src.tactics.ui.panels.battle")
local control_hints = require("src.tactics.ui.panels.control_hints")

local text_node = require("src.tactics.ui.components.text_node")
local nested_list = require("src.tactics.menu.cursor.nested.list")
local book = require("src.tactics.ui.decoration.book")
local menu = require("src.tactics.ui.components.menu")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager

local battle_summary = battle.battle_summary()
local map = tactics_map.new(
	STATIC_CONFIG.MAP_WIDTH,
	STATIC_CONFIG.MAP_HEIGHT
)
local left = book.flex_page()
left:add(battle_summary)
left:add(battle.unit_info())
left:add(box.spacer(1))
left:add(control_hints.new())

local root = book.split_pages(left, map)

return { root = root }
