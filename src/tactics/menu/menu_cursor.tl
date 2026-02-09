---@brief
--- Defines the core interfaces and types for menu cursors, which
--- handle user navigation within a menu.

local menu_types = require("src.tactics.menu.types")
local input_service = require("src.tactics.joypad")
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext
local Joypad = input_service.Joypad
local Mouse = input_service.Mouse

local enum CursorType
    "selection"
    "button"
    "multiple_options"
    "nested"
end

local enum NestedCursorType
	"row"
	"col"
	"grid"
end

local type MenuHandler = function(self, GameContext, MenuContext)

local interface MenuMouseSelection
	type: CursorType
end

local record Grid
	is MenuMouseSelection
	where self.type == "grid"
	x: integer
	y: integer
end

local record Button
	is MenuMouseSelection
	where self.type == "button"
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
	Button = Button,
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
		type = "selection",
		i = i,
	}
	return self
end

local interface MenuNode
    type: CursorType
    update_joy: function(self, Joypad) 
    update_mouse: function(self, Mouse, MenuMouseSelection) 
--- @return next state
    handle_select: function(self, game_context: GameContext, menu_ctx: MenuContext, menu_state: menu_types.MenuState): string 
    handle_back: function(self, game_context: GameContext, menu_ctx: MenuContext) 
end

local interface MenuNodeDefinition
    type: CursorType
    previous_state: menu_types.MenuStep
    to_cursor: function(self, game_ctx: GameContext, menu_ctx: MenuContext, menu_state: menu_types.MenuState): MenuNode
end

local menu_cursor = {
	MenuHandler = MenuHandler,
    CursorType = CursorType,
    MenuNode = MenuNode,
    MenuNodeDefinition = MenuNodeDefinition,

    mouse_selection = mouse_selection,
}

return menu_cursor
