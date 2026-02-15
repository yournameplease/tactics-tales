local box = require("src.tactics.ui.box")
local UIContextManager = require("src.tactics.ui.ui_context_manager").UIContextManager
local nested_list = require("src.tactics.menu.cursor.nested.list")
local menu_mouse_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuNode = menu_cursor.MenuNode
local button = require("src.tactics.menu.cursor.button")
local ButtonCursor = button.ButtonCursor
local SelectionMenuNode = require("src.tactics.menu.cursor.selection").SelectionMenuNode


local menu = {}

function menu.text_button(
	b: ButtonCursor
): box.UIElement
	log.debug("Generating button node menu box. ",b.id,b.text)
	return box.builder("button")
	:layout{
		width = "fit_content",
		padding = box.layout.padding(2),
	}
	:text{
		content = {b.text},
		draw_properties = {
			wrap = "no_wrap",
		},
	}
	:style{
		decoration_padding = 2,
	}
	:on_update(function(self: box.UIElement, _state: UIContextManager)
		local has_focus = b.has_focus

		self.style.decoration = has_focus and "border" or nil
	end)
	:menu_handling{
		hover_event = menu_mouse_selection.leaf(b, "button_primary", "button_secondary"),
	}
	:build()
end

function menu.select_row(
	node: SelectionMenuNode
): box.UIElement
	log.debug("Generating select node menu box. ",node.id,node.label)
	local row = box.builder(node.id)
		:direction("row")
		:container("strip")
		:build()

	if node.label then
		row:add(
			box.builder(node.id.."_label")
			:layout({
				width = "fit_content"
			})
			:text{
				rows = 1,
				content = { node.label },
				draw_properties = {
					wrap = "no_wrap",
				},
			}
			:build())
	end
	row:add(box.spacer(1))
	row:add(
		box.builder(node.id.."left")
		:layout{
			width = 9,
			height = 9,
		}
		:sprite{
			s = 22,
			ox = 1,
			oy = 1,
		}
		:menu_handling{
			hover_event = menu_mouse_selection.leaf(node, "decrement_selection", nil),
		}
		:build())
	row:add(
		box.builder(node.id.."_text")
		:layout({
			width = "fit_content"
		})
		:text{
			rows = 1,
			content = { node.label },
			draw_properties = {
				wrap = "no_wrap",
			},
		}
		:on_update(function(self: box.UIElement, _state: UIContextManager)
			self.text.content[1] = node:get_selected_text()
		end)
		:build())
	row:add(
		box.builder(node.id.."right")
		:layout{
			width = 9,
			height = 9,
		}
		:sprite{
			s = 23,
			ox = 1,
			oy = 1,
		}
		:menu_handling{
			hover_event = menu_mouse_selection.leaf(node, "increment_selection", nil),
		}
		:build())

	return row
end

function menu.select_modal_row(
	node: SelectionMenuNode
): box.UIElement
	log.debug("Generating select node menu box. ",node.id,node.label)
	local row = box.builder(node.id)
		:direction("row")
		:container("modal")
		:build()

	if node.label then
		row:add(
			box.builder(node.id.."_label")
			:layout({
				width = "fit_content"
			})
			:text{
				rows = 1,
				content = { node.label },
				draw_properties = {
					wrap = "no_wrap",
				},
			}
			:build())
	end
	row:add(
		box.builder(node.id.."left")
		:layout{
			width = 9,
			height = 9,
		}
		:sprite{
			s = 22,
			ox = 1,
			oy = 1,
		}
		:menu_handling{
			hover_event = menu_mouse_selection.leaf(node, "decrement_selection", nil),
		}
		:build())
	row:add(
		box.builder(node.id.."_text")
		:layout({
			width = "fit_content"
		})
		:text{
			rows = 1,
			content = { node.label },
			draw_properties = {
				wrap = "no_wrap",
			},
		}
		:on_update(function(self: box.UIElement, _state: UIContextManager)
			self.text.content[1] = node:get_selected_text()
		end)
		:build())
	row:add(
		box.builder(node.id.."right")
		:layout{
			width = 9,
			height = 9,
		}
		:sprite{
			s = 23,
			ox = 1,
			oy = 1,
		}
		:menu_handling{
			hover_event = menu_mouse_selection.leaf(node, "increment_selection", nil),
		}
		:build())

	return row
end

local function generate_menu_node_element(
	node: MenuNode
): box.UIElement
	if node is nested_list.NestedMenuNode then
		local builder = box.builder(node.id)
		if node.direction == "column" then
			builder = builder
				:direction("col")
				:container("block")
		elseif node.direction == "row" then
			builder = builder
				:direction("row")
				:container("strip")
		end

		local self = builder:build()

		if node.direction == "row" then
			self:add(box.spacer(1))
		end
		for _,child in ipairs(node.children) do
			self:add(generate_menu_node_element(child))
			if node.direction == "row" then
				self:add(box.spacer(1))
			end
		end

		return self
	elseif node is ButtonCursor then
		return menu.text_button(node)
	elseif node is SelectionMenuNode then
		if node.direction == "vertical" then
			-- child_box = flex_col
			todo()
		elseif node.direction == "horizontal" then
			return menu.select_row(node)
		end
	end
end

local function generate_menu_modal_element(
	node: MenuNode
): box.UIElement
	if node is nested_list.NestedMenuNode then
		local builder = box.builder(node.id)
		if node.direction == "column" then
			builder = builder
				:direction("col")
				:container("modal")
				
		elseif node.direction == "row" then
			builder = builder
				:direction("row")
				:container("modal")
		end

		local self = builder:build()

		for _,child in ipairs(node.children) do
			self:add(generate_menu_node_element(child))
		end

		return self
	elseif node is ButtonCursor then
		return menu.text_button(node)
	elseif node is SelectionMenuNode then
		if node.direction == "vertical" then
			-- child_box = flex_col
			todo()
		elseif node.direction == "horizontal" then
			return menu.select_modal_row(node)
		end
	end
end

local function generate_menu_root_children(
	menu_cursor_func: function(UIContextManager): MenuNode
): function(state: UIContextManager): {box.UIElement}
	return function(state: UIContextManager): {box.UIElement}
		local node = menu_cursor_func(state)

		return {generate_menu_node_element(node)}
	end
end

local function generate_menu_modal_root_children(
	menu_cursor_func: function(UIContextManager): MenuNode
): function(state: UIContextManager): {box.UIElement}
	return function(state: UIContextManager): {box.UIElement}
		local node = menu_cursor_func(state)

		return {generate_menu_modal_element(node)}
	end
end

function menu.generic_menu_box(
	menu_revision_func: function(UIContextManager): integer,
	menu_cursor_func: function(UIContextManager): MenuNode
): box.UIElement
	return box.builder("menu_container")
	:child_generator{
		current_key = menu_revision_func,
		generate_children = generate_menu_root_children(menu_cursor_func)
	}
	:build()

end

function menu.generic_menu_modal(
	menu_revision_func: function(UIContextManager): integer,
	menu_cursor_func: function(UIContextManager): MenuNode
): box.UIElement
	return box.builder("menu_container")
	:child_generator{
		current_key = menu_revision_func,
		generate_children = generate_menu_modal_root_children(menu_cursor_func)
	}
	:build()

end

return menu
