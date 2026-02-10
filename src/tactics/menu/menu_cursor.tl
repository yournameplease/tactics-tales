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

local enum MenuSignalType
    "navigate"
    "ignored" -- input was not used; should bubble up to parent
	"consumed" -- input was used, but no actions
    "back"
end

local interface MenuSignal
	type: MenuSignalType
end

local record MenuSignalBack
	is MenuSignal
	where self.type == "back"
end

local record MenuSignalConsumed
	is MenuSignal
	where self.type == "consumed"
end

local record MenuSignalIgnored
	is MenuSignal
	where self.type == "ignored"
end

local record MenuSignalNavigate
	is MenuSignal
	where self.type == "navigate"
	target: string
end

local menu_signal = {
	MenuSignal = MenuSignal,
	Back = MenuSignalBack,
	Consumed = MenuSignalConsumed,
	Ignored = MenuSignalIgnored,
	Navigate = MenuSignalNavigate,
}

function menu_signal.back(): MenuSignal
	return {
		type = "back"
	}
end

function menu_signal.consumed(): MenuSignal
	return {
		type = "consumed"
	}
end

function menu_signal.ignored(): MenuSignal
	return {
		type = "ignored"
	}
end

function menu_signal.navigate(target: string): MenuSignal
	local out: MenuSignalNavigate = {
		type = "navigate",
		target = target,
	}
	return out
end

local record MenuSignalNavigate
	is MenuSignal
	where self.type == "navigate"
	target: string
end

local enum MenuLeafType
    "selection"
    "button"
end

local enum MenuContainerType
	"list"
	"grid"
end

local enum CursorType
    "selection"
    "button"
	"row"
	"column"
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
	where self.type == "selection"
	i: integer
end

local mouse_selection = {
	MenuMouseSelection = MenuMouseSelection,
	Grid = Grid,
	Button = Button,
	List = List,
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
    update_joy: function(self, Joypad, game_context: GameContext, menu_ctx: MenuContext): MenuSignal
    update_mouse: function(self, Mouse, MenuMouseSelection, game_context: GameContext, menu_ctx: MenuContext): MenuSignal
end

local interface MenuLeaf
	is MenuNode
    type: MenuLeafType
--- @return next state
end

local interface MenuContainer
	is MenuNode
    type: MenuContainerType
    get_focused_leaf: function(self): MenuLeaf
end

local interface MenuNodeDefinition
    to_cursor: function(self, game_ctx: GameContext, menu_ctx: MenuContext, menu_state: menu_types.MenuState): MenuNode
end

local interface MenuLeafDefinition
	is MenuNodeDefinition
    type: MenuLeafType
end

local interface MenuContainerDefinition
	is MenuNodeDefinition
    type: MenuContainerType
end

local menu_cursor = {
	MenuHandler = MenuHandler,
    MenuNode = MenuNode,
    MenuLeaf = MenuLeaf,
    MenuContainer = MenuContainer,
    MenuNodeDefinition = MenuNodeDefinition,
    MenuLeafDefinition = MenuLeafDefinition,
    MenuContainerDefinition = MenuContainerDefinition,

    mouse_selection = mouse_selection,

    menu_signal = menu_signal,
}

return menu_cursor
