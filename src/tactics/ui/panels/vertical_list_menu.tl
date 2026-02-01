---@brief
--- A reusable UI panel for displaying a vertical list menu.

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local text_node = require("src.tactics.ui.components.text_node")
local list_cursor = require("src.tactics.menu.cursor.list_cursor")
local String = require("src.tactics.util.string")
local menu_mouse_selection = require("src.tactics.menu.menu_cursor").mouse_selection

local record VerticalListMenu<GC, Value>
    is text_node.TextUIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): list_cursor.ListMenuCursor<GC, Value>
end
setmetatable(VerticalListMenu, { __index = text_node.TextNode })

local vertical_list_menu = {}

function VerticalListMenu:get_selection_at(lx: number, ly: number): menu_mouse_selection.MenuMouseSelection
	local line = self:get_hovered_line(lx, ly)

	return menu_mouse_selection.list(line)
end

function vertical_list_menu.new<GC, Value>(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): list_cursor.ListMenuCursor<GC, Value>,
	props: text_node.TextNode
): box.UIElement
	
    props.func = function(state: UIContextManager): { string }
        local out = {}
		local cursor: list_cursor.ListMenuCursor<GC, Value> = menu_cursor_func(state)
		local selected = cursor.i
		for i,opt in ipairs(cursor.options) do
			local template = i == selected and selected_template or unselected_template
			local out_line = String.format(template, { ["text"] = opt.text })
			pt.add(out, out_line)
		end
		return out
    end

    props.draw_properties = props.draw_properties or {}
    props.draw_properties.direction = props.draw_properties.direction or 'down'
	props.get_selection_at = VerticalListMenu.get_selection_at

    local self = text_node.new(props)
	setmetatable(self, { __index = VerticalListMenu })

	return self
end

return vertical_list_menu

