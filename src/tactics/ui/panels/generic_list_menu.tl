
---@brief
--- A reusable UI panel for displaying a vertical list menu.

local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local text_node = require("src.tactics.ui.components.text_node")
local text_button = require("src.tactics.ui.panels.text_button")
local nested_list = require("src.tactics.menu.cursor.nested.list")
local String = require("src.tactics.util.string")
local sprite_node = require("src.tactics.ui.components.sprite_node")
local menu_mouse_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNode = menu_cursor.MenuNode
local button = require("src.tactics.menu.cursor.button")
local ButtonCursor = button.ButtonCursor
local SelectionMenuNode = require("src.tactics.menu.cursor.selection").SelectionMenuNode

local record GenericMenuBox
    is box.UIElement
	unselected_template: string
	selected_template: string
	menu_cursor_func: function(UIContextManager): MenuNode

	
end
setmetatable(GenericMenuBox, { __index = box.Box })

local generic_menu_box = {}

function GenericMenuBox:get_selection_at(lx: number, ly: number): menu_mouse_selection.MenuMouseSelection
	-- local line = self:get_hovered_line(lx, ly)

	-- return menu_mouse_selection.list(line, "button_primary", "button_secondary")
	return nil
end

function generic_menu_box.new(
	unselected_template: string,
	selected_template: string,
	menu_cursor_func: function(UIContextManager): MenuNode,
	props: box.UIElement
): GenericMenuBox
	
    local self = box.new(props) as GenericMenuBox
	setmetatable(self, { __index = GenericMenuBox })

	self.unselected_template = unselected_template
	self.selected_template = selected_template
	self.menu_cursor_func = menu_cursor_func
	return self
end

function GenericMenuBox:compute_children(state: UIContextManager)
	local node = self.menu_cursor_func(state)

	-- todo: real caching
	if self.children ~= nil and #self.children ~= 0 then return end
	local children: {box.UIElement} = {}
	
	if node is nested_list.NestedMenuNode then
		if node.direction == "column" then
			self.dir = "col"
		elseif node.direction == "row" then
			self.dir = "row"
		end

		for _,child in ipairs(node.children) do
			local child_box = generic_menu_box.new(
				self.unselected_template,
				self.selected_template,
				function(_: UIContextManager): MenuNode
					return child
				end,
				{ flex_grow = 1 }
			)
			child_box:compute_children(state)
			pt.add(children, child_box)
		end
	elseif node is ButtonCursor then
		local child_box = text_button.new(
			self.unselected_template,
			self.selected_template,
			function(_: UIContextManager): MenuNode
				return node
			end,
			{
				flex_grow = 1,
				auto_height = true,
			}
		)
		pt.add(children, child_box)
	elseif node is SelectionMenuNode then
		local child_box: box.UIElement
		if node.direction == "vertical" then
			-- child_box = flex_col
		elseif node.direction == "horizontal" then
			child_box = box.flex_row()
			if node.label then
				child_box:add(text_node.new{
					text = {node.label}
				})
			end
			sprite_node.static(22, {})
			child_box:add(text_node.new{
				text = {node:get_selected_text()},
				flex_grow = 1,
				auto_height = true,
			})
			sprite_node.static(23, {})
		end
	end
	self.children = children
end

return generic_menu_box

