require("src/tactics/debug")
require("src/tactics/ui/box")
require("src/tactics/systems/event_bus")
require("src/tactics/ui/ui_context_manager")
require("src/tactics/story/story_menu_context")
local text_node = require("src/tactics/ui/components/text_node")
local list_cursor = require("src/tactics/menu/cursor/list_cursor")
local String = require("src/tactics/util/string")

local record VerticalListMenu<GC, Value>
    is UIElement, TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): list_cursor.ListMenuCursor<GC, Value>
end
 
function VerticalListMenu.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): list_cursor.ListMenuCursor<GC, Value>,
	props: TextNode
): VerticalListMenu<GC, Value>
	
    props.func = function(state: UIContextManager): { string }
        local out = {}
		local cursor: list_cursor.ListMenuCursor<GC, Value> = menu_cursor_func(state)
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
    props.draw_properties.direction = props.draw_properties.direction or 'down'
    return text_node.new(props) as VerticalListMenu
end

return VerticalListMenu

