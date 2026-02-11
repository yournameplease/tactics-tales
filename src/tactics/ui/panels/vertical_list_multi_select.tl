---@brief
--- A reusable UI panel for displaying a vertical menu with
--- multiple independent options.

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local text_node = require("src.tactics.ui.components.text_node")
local nested_list = require("src.tactics.menu.cursor.nested.list")
local menu_mouse_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local String = require("src.tactics.util.string")
local SelectionMenuNode = require("src.tactics.menu.cursor.selection").SelectionMenuNode

local record VerticalSelectionList
    is box.UIElement, text_node.TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): nested_list.NestedMenuNode
end

function VerticalSelectionList:get_selection_at(lx: number, ly: number): menu_mouse_selection.MenuMouseSelection
	local line = self:get_hovered_line(lx, ly)

	-- todo: button hovers
	return menu_mouse_selection.list(line, "increment_selection", nil)
end
 
function VerticalSelectionList.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): nested_list.NestedMenuNode,
	props: text_node.TextNode
): VerticalSelectionList
	
    props.func = function(state: UIContextManager): { string }
        local out = {}
		local cursor  = menu_cursor_func(state)
		local selected = cursor.i
		for i,child in ipairs(cursor.children) do
			if child is SelectionMenuNode then
				local template = i == selected and selected_template or unselected_template
				local out_line = String.format(
					template,
					{
						["label"] = child.label,
						["value"] = child.options[child.i].text,
					}
				)
				pt.add(out, out_line)
			else
				pt.add(out, "ERROR: Missing button")
			end
		end
		return out
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.direction = props.draw_properties.direction or 'down'
    props.draw_properties.wrap = props.draw_properties.wrap or 'no_wrap'
    return text_node.new(props) as VerticalSelectionList
end

return VerticalSelectionList


