---@brief
--- Defines the main UI layout for the tactical battle screen.

require("src.tactics.config")

local tactics_map = require("src.tactics.ui.panels.tactics_map")
local box = require("src.tactics.ui.box")
local battle = require("src.tactics.ui.panels.battle")
local control_hints = require("src.tactics.ui.panels.control_hints")

local book = require("src.tactics.ui.decoration.book")
local UILayoutId = require("src.tactics.ui.types").UILayoutId
local layout = require("src.tactics.ui.layout")
local tactics_modal = require("src.tactics.ui.modal.tactics")

local layouts: { UILayoutId: layout.UILayout }  = {}

local battle_summary = battle.battle_summary()
local map = tactics_map.new(
	STATIC_CONFIG.MAP_WIDTH,
	STATIC_CONFIG.MAP_HEIGHT
)

local modals: {layout.ModalLayout} = {
	{
		node = tactics_modal.tactics_dialogue_menu(),
	},
	{
		node = tactics_modal.tactics_action_menu(),
	},
}

do 
	local left = book.flex_page()
	left:add(battle_summary)
	left:add(battle.unit_info())
	left:add(box.spacer(1))
	left:add(control_hints.new())
	local right = book.fit_page()
	right:add(map)

	layouts["TACTICS"] = {
		root = book.split_pages(left, map),
		modals = modals,
	}
end

do 
	local left = book.flex_page()
	left:add(battle_summary)
	left:add(battle.combat_preview())
	left:add(box.spacer(1))
	left:add(control_hints.new())
	local right = book.fit_page()
	right:add(map)

	layouts["COMBAT_PREVIEW"] = {
		root = book.split_pages(left, map),
		modals = modals,
	}
end

return layouts
