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
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNode = menu_cursor.MenuNode

local record TextButton
    is text_node.TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): ButtonCursor

    menu_node: ButtonCursor
end
setmetatable(TextButton, { __index = text_node.TextNode })

local text_button = {}

function TextButton:get_selection_at(_lx: number, _ly: number): menu_mouse_selection.MenuMouseSelection
	return menu_mouse_selection.leaf(self.menu_node, "button_primary", "button_secondary")
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

    local self = text_node.new(props) as TextButton
	setmetatable(self, { __index = TextButton })

	self.menu_cursor_func = menu_cursor_func
	return self
end

function TextButton:compute_children(state: UIContextManager)
	if self.menu_node == nil then
		-- todo: or if dirty?
	    self.menu_node = self.menu_cursor_func(state)
	end
	
	text_node._compute_children(self as text_node.TextNode, state)
end

return text_button

