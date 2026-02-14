---@brief
--- A reusable UI panel for displaying a single text button.

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local menu_mouse_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local button = require("src.tactics.menu.cursor.button")
local ButtonCursor = button.ButtonCursor

local text_button = {}

function text_button.new(
	b: ButtonCursor
): box.UIElement
	return box.builder("button")
	:text{
		content = {b.text}
	}
	:on_update(function(self: box.UIElement, _state: UIContextManager)
		local has_focus = b.has_focus

		self.style.decoration = has_focus and "border" or nil
	end)
	:menu_handling{
		hover_event = menu_mouse_selection.leaf(b, "button_primary", "button_secondary"),
	}
	:build()
end

return text_button

