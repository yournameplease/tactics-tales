local menu_types = require("src/tactics/menu/types")
local event_bus = require("src/tactics/systems/event_bus")
local input_service = require("src/tactics/joypad")
local Joypad = input_service.Joypad
local Mouse = input_service.Mouse

local enum CursorType
    "grid"
    "list"
    "button_advance"
    "multiple_options"
end

local interface MenuMouseSelection
	type: CursorType
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
	i: integer
end

local record MultipleOptions
	is MenuMouseSelection
	where self.type == "multiple_options"
end

local mouse_selection = {
	MenuMouseSelection = MenuMouseSelection,
	Grid = Grid,
	ButtonAdvance = ButtonAdvance,
	List = List,
	MultipleOptions = MultipleOptions,
}

function mouse_selection.grid(x: integer, y: integer): MenuMouseSelection
	local self: Grid =  {
		type = "grid",
		x = x,
		y = y,
	}
	return self
end

function mouse_selection.list(i: integer): MenuMouseSelection
	local self: List =  {
		type = "list",
		i = i,
	}
	return self
end

local interface MenuCursor<GC, MenuContext>
    type: CursorType
    update_joy: function(self, Joypad) 
    update_mouse: function(self, Mouse, MenuMouseSelection) 
--- @return next state
--- @return send command
    handle_select: function(self, game_context: GC, menu_ctx: MenuContext, menu_state: menu_types.MenuState): string, event_bus.GameEvent
    handle_back: function(self, game_context: GC, menu_ctx: MenuContext, menu_state: menu_types.MenuState): event_bus.GameEvent
end

local interface MenuStepDefinition<GC, MenuContext>
    type: CursorType
    previous_state: menu_types.MenuStep
    to_cursor: function(self, game_ctx: GC, menu_ctx: MenuContext, menu_state: menu_types.MenuState): MenuCursor<GC>
end

local menu_cursor = {
    CursorType = CursorType,
    MenuCursor = MenuCursor,
    MenuStepDefinition = MenuStepDefinition,

    mouse_selection = mouse_selection,
}

return menu_cursor
