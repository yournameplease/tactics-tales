local menu_cursor = require("src/tactics/menu/menu_cursor")

local interface MenuMouseSelection
	type: menu_cursor.CursorType
end

local record Grid
	is MenuMouseSelection
	where self.type == "grid"
	x: integer
	y: integer
end

local record ButtonAdvance
	is MenuMouseSelection
	where self.type == "button_advance"
end

local record List
	is MenuMouseSelection
	where self.type == "list"
end

local record MultipleOptions
	is MenuMouseSelection
	where self.type == "multiple_options"
end

local mouse_menu_selection = {
	MenuMouseSelection = MenuMouseSelection,
	Grid = Grid,
	ButtonAdvance = ButtonAdvance,
	List = List,
	MultipleOptions = MultipleOptions,
}

function mouse_menu_selection.grid(x: integer, y: integer): MenuMouseSelection
	local self: Grid =  {
		type = "grid",
		x = x,
		y = y,
	}
	return self
end


return mouse_menu_selection
