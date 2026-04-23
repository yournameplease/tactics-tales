---@brief
--- UI component builders for menu cursors: converts MenuNode trees into
--- UIElement hierarchies used by the box layout engine.

local box = require("src.tactics.ui.box")
local point = require("src.tactics.util.point")
local menu_mouse_selection = require("src.tactics.menu.menu_cursor").mouse_selection

local menu = {}

--- Build a button box element that shows focus decoration and handles mouse hover.
---@param b ButtonCursor
---@return UIElement
function menu.text_button(b)
	-- log.debug("Generating button node menu box. ",b.id,b.text)
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
	:on_update(function(self, _state)
		local has_focus = b.has_focus

		self.style.decoration = has_focus and "border" or nil
	end)
	:menu_handling{
		hover_event = menu_mouse_selection.leaf(b, "select", "back"),
	}
	:build()
end

--- Build a single grid-cell button that tracks cursor focus and mouse hover.
---@param node NestedGridNode
---@param p Point
---@return UIElement
local function grid_button(node, p)
	-- log.debug("Generating button node menu box. ",b.id,b.text)
	log.debug("Creating grid button: ", p, node.id)

	return box.builder("button")
		:layout{
			width = 16,
			height = 16,
			-- flex_grow = 1,
			padding = box.layout.padding(2),
		}
		:text{
			draw_properties = {
				wrap = "no_wrap",
			},
		}
		:style{
			decoration_padding = 2,
		}
		:on_update(function(self, _state)
			local has_focus = node.has_focus and node.point == p

			local text = node.text_array:get_point(p)
			self.text.content = {text}
			self.style.decoration = has_focus and "border" or nil
		end)
		:menu_handling{
			hover_event = menu_mouse_selection.grid(p.x, p.y, node, "select", "back"),
		}
		:build()
end

--- Build a horizontal selection row with left/right arrows for the strip container style.
---@param node SelectionMenuNode
---@return UIElement
function menu.select_row(node)
	log.debug("Generating select node menu box. ",node.id,node.label)
	local row = box.builder(node.id)
		:direction("row")
		:container("strip")
		:padding(2)
		:style{
			decoration_padding = 2,
		}
		:on_update(function(self, _state)
			local has_focus = node.has_focus

			self.style.decoration = has_focus and "border" or nil
		end)
		:menu_handling{
			hover_event = menu_mouse_selection.leaf(node, nil, nil),
		}
		:build()

	if node.label then
		row:add(
			box.builder(node.id.."_label")
			:layout({
				width = "fit_content"
			})
			:padding(1)
			:text{
				rows = 1,
				content = { node.label },
				draw_properties = {
					wrap = "no_wrap",
				},
			}
			:build())
	end
	row:add(box.spacer(2))
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
		:layout{
			width = 80,
		}
		:padding(1)
		:text{
			rows = 1,
			content = { node.label },
			draw_properties = {
				wrap = "no_wrap",
				justify = "center",
			},
		}
		:on_update(function(self, _state)
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

--- Build a horizontal selection row with left/right arrows for the modal container style.
---@param node SelectionMenuNode
---@return UIElement
function menu.select_modal_row(node)
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
		:on_update(function(self, _state)
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

--- Recursively convert a MenuNode into a UIElement for the strip/block container style.
---@param node MenuNode
---@return UIElement?
local function generate_menu_node_element(node)
	if node.type == "grid" then
		---@cast node NestedGridNode
		local outer_row = box.builder(node.id.."_outer_row")
				:direction("row")
				:container("strip")
				:build()
		outer_row:add(box.spacer(1))
		local column = box.builder(node.id.."_column")
				:direction("col")
				:container("modal")
				:build()
		outer_row:add(column)
		outer_row:add(box.spacer(1))

		for y=1,node.y_max do
			local row = box.builder(node.id.."_row_"..y)
					:direction("row")
					:container("modal")
					:build()
			for x=1,node.x_max do
				local p = point.of(x-1, y-1)
				row:add(grid_button(node, p))
			end
			column:add(row)
		end

		return outer_row
	elseif node.type == "list" then
		---@cast node NestedMenuNode
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
			local element = generate_menu_node_element(child)
			if element then self:add(element) end
			if node.direction == "row" then
				self:add(box.spacer(1))
			end
		end

		return self
	elseif node.type == "button" then
		---@cast node ButtonCursor
		return menu.text_button(node)
	elseif node.type == "selection" then
		---@cast node SelectionMenuNode
		if node.direction == "vertical" then
			-- child_box = flex_col
			todo()
			return nil
		elseif node.direction == "horizontal" then
			return menu.select_row(node)
		end
	end
end

--- Recursively convert a MenuNode into a UIElement for the modal container style.
---@param node MenuNode
---@return UIElement?
local function generate_menu_modal_element(node)
	if node.type == "list" then
		---@cast node NestedMenuNode
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
			local element = generate_menu_node_element(child)
			if element then self:add(element) end
		end

		return self
	elseif node.type == "button" then
		---@cast node ButtonCursor
		return menu.text_button(node)
	elseif node.type == "selection" then
		---@cast node SelectionMenuNode
		if node.direction == "vertical" then
			-- child_box = flex_col
			todo()
			return nil
		elseif node.direction == "horizontal" then
			return menu.select_modal_row(node)
		end
	end
end

--- Return a child-generator function that wraps the menu node in a strip element.
---@param menu_cursor_func fun(state: table): MenuNode
---@return fun(state: table): UIElement[]
local function generate_menu_root_children(menu_cursor_func)
	return function(state)
		local node = menu_cursor_func(state)

		return {generate_menu_node_element(node)}
	end
end

--- Return a child-generator function that wraps the menu node in a modal element.
---@param menu_cursor_func fun(state: table): MenuNode
---@return fun(state: table): UIElement[]
local function generate_menu_modal_root_children(menu_cursor_func)
	return function(state)
		local node = menu_cursor_func(state)

		return {generate_menu_modal_element(node)}
	end
end

--- Build a generic menu container box that regenerates its children when the revision key changes.
---@param menu_revision_func fun(state: table): integer
---@param menu_cursor_func fun(state: table): MenuNode
---@return UIElement
function menu.generic_menu_box(menu_revision_func, menu_cursor_func)
	return box.builder("menu_container")
	:child_generator{
		current_key = menu_revision_func,
		generate_children = generate_menu_root_children(menu_cursor_func)
	}
	:build()
end

--- Build a generic modal menu container that regenerates its children when the revision key changes.
---@param menu_revision_func fun(state: table): integer
---@param menu_cursor_func fun(state: table): MenuNode
---@return UIElement
function menu.generic_menu_modal(menu_revision_func, menu_cursor_func)
	return box.builder("menu_container")
	:direction("col")
	:container("modal")
	:child_generator{
		current_key = menu_revision_func,
		generate_children = generate_menu_modal_root_children(menu_cursor_func)
	}
	:build()
end

---@param node MenuNode
---@return string[]
local function find_focused_description(node)
	if not node.has_focus then return {} end
	if node.type == "list" then
		---@cast node NestedMenuNode
		local child = node:get_selected_child()
		if child then
			local desc = find_focused_description(child)
			if desc then return desc end
		end
	elseif node.type == "button" then
		---@cast node ButtonCursor
		return {node.description}
	elseif node.type == "selection" then
		---@cast node SelectionMenuNode
		local description = node.description
		local name = node:get_selected_text()
		local selection_description = node:get_selected_description()

		local out = {}
		if description then
			table.insert(out, description)
		end
		if selection_description and #selection_description > 0 then
			if name and selection_description then
				table.insert(out, name..": "..selection_description)
			else
				table.insert(out, selection_description)
			end
		end
		return out
	end

	return {}
end

--- Build a text box that shows the description of the currently focused
--- menu node, updating automatically as focus changes.
---@param node MenuNode
---@return UIElement
function menu.menu_description(node)
	return box.builder("menu_description")
		:layout{
			dir = "col",
			width = "fill",
			height = 100,
		}
		:text{
			content = { "" },
			draw_properties = { wrap = "wrap" },
		}
		:on_update(function(self, _state)
			self.text.content = find_focused_description(node) or {""}
		end)
		:build()
end

--- Return a child-generator function that wraps the menu node in a modal element.
---@param menu_cursor_func fun(state: table): MenuNode
---@return fun(state: table): UIElement[]
local function generate_menu_description_children(menu_cursor_func)
	return function(state)
		local node = menu_cursor_func(state)

		return {menu.menu_description(node)}
	end
end

--- Build a generic modal menu container that regenerates its children when the revision key changes.
---@param menu_revision_func fun(state: table): integer
---@param menu_cursor_func fun(state: table): MenuNode
---@return UIElement
function menu.generic_menu_description(menu_revision_func, menu_cursor_func)
	return box.builder("menu_description_container")
	:direction("col")
	:container("panel")
	:child_generator{
		current_key = menu_revision_func,
		generate_children = generate_menu_description_children(menu_cursor_func)
	}
	:build()
end

return menu
