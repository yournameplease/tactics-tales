require("src/debug")
require("src/ui/box")
require("src/systems/event_bus")
require("src/ui/components/text_node")
require("src/ui/ui_context_manager")
require("src/story/story_context")
require("src/menu/cursor/list_cursor")
local String = require("src/util/string")

local record VerticalListMenu<T>
    is UIElement, TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): ListMenuCursor<T>
end
 
function VerticalListMenu.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): ListMenuCursor<T>,
	props: TextNode
): VerticalListMenu<T>
	
    props.func = function(state: UIContextManager): { string }
        local out = {}
		local cursor: ListMenuCursor<T> = menu_cursor_func(state)
		local selected = cursor.i
		LOG.trace("rendering options: ", #cursor.options, selected)
		for i,opt in ipairs(cursor.options) do
			local template = i == selected and selected_template or unselected_template
			local out_line = String.format(template, { ["text"] = opt.text })
			LOG.trace("out line", template, out_line)
			pt.add(out, out_line)
		end
		return out
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.text_direction = props.draw_properties.text_direction or 'down'
    return TextNode.new(props) as VerticalListMenu
end

return VerticalListMenu

