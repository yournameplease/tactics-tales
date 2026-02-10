---@brief
--- A reusable UI panel for displaying a vertical menu with
--- multiple independent options.

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local text_node = require("src.tactics.ui.components.text_node")
local nested_cursor = require("src.tactics.menu.cursor.nested_cursor")
local multiple_options_cursor = require("src.tactics.menu.cursor.multiple_options_cursor")
local String = require("src.tactics.util.string")

local record VerticalMultiSelectMenu<T>
    is box.UIElement, text_node.TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): multiple_options_cursor.MultipleOptionsMenuNode<T>
end
 
function VerticalMultiSelectMenu.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): multiple_options_cursor.MultipleOptionsMenuNode<T>,
	props: text_node.TextNode
): VerticalMultiSelectMenu<T>
	
    props.func = function(state: UIContextManager): { string }
        local out = {}
		local cursor: multiple_options_cursor.MultipleOptionsMenuNode = menu_cursor_func(state)
		local selected = cursor.i
		for i,opt in ipairs(cursor.options) do
			local template = i == selected and selected_template or unselected_template
			local subcursor = opt.cursor
			assert(subcursor is list_cursor.ListMenuNode<string|integer>, "Only list cursor is implemented!") 
			local out_line = String.format(
				template,
				{
					["label"] = opt.text,
					["value"] = subcursor.options[subcursor.i].text,
				}
			)
			pt.add(out, out_line)
		end
		return out
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.direction = props.draw_properties.direction or 'down'
    props.draw_properties.wrap = props.draw_properties.wrap or 'no_wrap'
    return text_node.new(props) as VerticalMultiSelectMenu
end

return VerticalMultiSelectMenu


