---@brief
--- A reusable UI panel for displaying a single text button.

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local text_node = require("src.tactics.ui.components.text_node")
local nested_list = require("src.tactics.menu.cursor.nested.list")
local String = require("src.tactics.util.string")
local menu_mouse_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local button = require("src.tactics.menu.cursor.button")
local ButtonCursor = button.ButtonCursor

local record TextButton
    is text_node.TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): nested_list.NestedMenuNode
end
setmetatable(TextButton, { __index = text_node.TextNode })

local text_button = {}

function TextButton:get_selection_at(lx: number, ly: number): menu_mouse_selection.MenuMouseSelection
	local line = self:get_hovered_line(lx, ly)

	return menu_mouse_selection.list(line, "button_primary", "button_secondary")
end

function text_button.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): ButtonCursor,
	props: text_node.TextNode
): box.UIElement
	
    props.func = function(state: UIContextManager): { string }
		local cursor: ButtonCursor = menu_cursor_func(state)
		-- todo: hover
		local template = true and selected_template or unselected_template
		local out_line = String.format(template, { ["text"] = cursor.text })
		return {out_line}
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.direction = props.draw_properties.direction or 'down'
	props.get_selection_at = TextButton.get_selection_at

    local self = text_node.new(props)
	setmetatable(self, { __index = TextButton })

	return self
end

return text_button

