---@brief
--- A reusable UI panel for displaying a vertical list menu.

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

local record VerticalButtonList
    is text_node.TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): nested_list.NestedMenuNode

    menu_node: nested_list.NestedMenuNode
end
setmetatable(VerticalButtonList, { __index = text_node.TextNode })

local vertical_list_menu = {}

function VerticalButtonList:get_selection_at(lx: number, ly: number): menu_mouse_selection.MenuMouseSelection
	local line = self:get_hovered_line(lx, ly)
	if self.menu_node == nil then return end
	if line < 1 or line > #self.menu_node.children then return end

	return menu_mouse_selection.leaf(self.menu_node.children[line], "button_primary", "button_secondary")
end

function vertical_list_menu.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): nested_list.NestedMenuNode,
	props: text_node.TextNode
): box.UIElement
	
    props.func = function(self: VerticalButtonList, state: UIContextManager): { string }
        local out: {string} = {}
		local cursor: nested_list.NestedMenuNode = self.menu_node
		local selected = cursor.i
		for i,child in ipairs(cursor.children) do
			if child is ButtonCursor then
				local template = i == selected and selected_template or unselected_template
				local out_line = String.format(template, { ["text"] = child.text })
				pt.add(out, out_line)
			else
				pt.add(out, "ERROR: Missing button")
			end
		end
		return out
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.direction = props.draw_properties.direction or 'down'
	props.get_selection_at = VerticalButtonList.get_selection_at

    local self = text_node.new(props) as VerticalButtonList
	setmetatable(self, { __index = VerticalButtonList })

	self.menu_cursor_func = menu_cursor_func
	return self
end

function VerticalButtonList:compute_children(state: UIContextManager)
	if self.menu_node == nil then
		-- todo: or if dirty?
	    self.menu_node = self.menu_cursor_func(state)
	end
	
	text_node._compute_children(self as text_node.TextNode, state)
end

return vertical_list_menu

