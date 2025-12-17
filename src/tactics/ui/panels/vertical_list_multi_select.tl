require("src/tactics/debug")
require("src/tactics/ui/box")
require("src/tactics/systems/event_bus")
require("src/tactics/ui/components/text_node")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/story/story_context")
require("src/tactics/menu/cursor/list_cursor")
require("src/tactics/menu/cursor/multiple_options_cursor")
local String = require("src/tactics/util/string")

local record VerticalMultiSelectMenu<T>
    is UIElement, TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): MultipleOptionsMenuCursor<T>
end
 
function VerticalMultiSelectMenu.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): MultipleOptionsMenuCursor<T>,
	props: TextNode
): VerticalMultiSelectMenu<T>
	
    props.func = function(state: UIContextManager): { string }
        local out = {}
		local cursor: MultipleOptionsMenuCursor<T> = menu_cursor_func(state)
		local selected = cursor.i
		LOG.trace("rendering options: ", #cursor.options, selected)
		for i,opt in ipairs(cursor.options) do
			local template = i == selected and selected_template or unselected_template
			local subcursor = opt.cursor
			assert(subcursor is ListMenuCursor<T>, "Only list cursor is implemented!") 
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
    props.draw_properties.text_direction = props.draw_properties.text_direction or 'down'
    return TextNode.new(props) as VerticalMultiSelectMenu
end

return VerticalMultiSelectMenu


