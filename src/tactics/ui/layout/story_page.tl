---@brief
--- Defines the UI layout for a story page.

local book = require("src.tactics.ui.decoration.book")
local story_page = require("src.tactics.ui.panels.story_page")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local box = require("src.tactics.ui.box")
local control_hints = require("src.tactics.ui.panels.control_hints")
local menu_manager = require("src.tactics.menu.menu_manager")

local left = book.flex_page()
left:add(box.spacer(1))
left:add(control_hints.new(
	function (s: UIContextManager): menu_manager.MenuStep
		return s.story_context.menu_manager.menu_step
	end
))

local right = book.flex_page()
right:add(story_page.new())

local root = book.split_pages(left, right)

return { root = root }
