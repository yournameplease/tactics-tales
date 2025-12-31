require("src/tactics/debug")
require("src/tactics/ui/box")
require("src/tactics/systems/event_bus")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/story/story_menu_context")
local text_node = require("src/tactics/ui/components/text_node")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local multiple_options_cursor = require("src/tactics/menu/cursor/multiple_options_cursor")
local String = require("src/tactics/util/string")

local record VerticalMultiSelectMenu<T>
    is UIElement, text_node.TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): multiple_options_cursor.MultipleOptionsMenuCursor<T>
end
 
function VerticalMultiSelectMenu.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): multiple_options_cursor.MultipleOptionsMenuCursor<T>,
	props: text_node.TextNode
): VerticalMultiSelectMenu<T>
	
    props.func = function(state: UIContextManager): { string }
        local out = {}
		local cursor: multiple_options_cursor.MultipleOptionsMenuCursor<T> = menu_cursor_func(state)
		local selected = cursor.i
		LOG.trace("rendering options: ", #cursor.options, selected)
		for i,opt in ipairs(cursor.options) do
			local template = i == selected and selected_template or unselected_template
			local subcursor = opt.cursor
			assert(subcursor is list_cursor.ListMenuCursor<T, string|integer>, "Only list cursor is implemented!") 
			local out_line = String.format(
				template,
				{
					["label"] = opt.text,
					["value"] = subcursor.options[subcursor.i].text,
				}
			)
			LOG.trace("out line", template, out_line)
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


