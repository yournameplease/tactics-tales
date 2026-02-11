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
    "call_handler"
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
	target: menu_types.MenuStep
end

local record MenuSignalCallHandler
	is MenuSignal
	where self.type == "call_handler"
	handler: menu_types.MenuHandlerId
	value: any -- typically the value of a button

	-- nillable
	then_navigate_to: menu_types.MenuStep
end

local menu_signal = {
	MenuSignal = MenuSignal,
	Back = MenuSignalBack,
	Consumed = MenuSignalConsumed,
	Ignored = MenuSignalIgnored,
	Navigate = MenuSignalNavigate,
	CallHandler = MenuSignalCallHandler
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

function menu_signal.navigate(target: menu_types.MenuStep): MenuSignal
	local out: MenuSignalNavigate = {
		type = "navigate",
		target = target,
	}
	return out
end

function menu_signal.call_handler(
	handler: menu_types.MenuHandlerId,
	value: any
): MenuSignalCallHandler
	local out: MenuSignalCallHandler = {
		type = "call_handler",
		handler = handler,
		value = value,
	}
	return out
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
	on_lmb_command: menu_types.MenuCommand
	on_rmb_command: menu_types.MenuCommand
end

local record Grid
	is MenuMouseSelection
	where self.type == "grid"
	x: integer
	y: integer
end

local record List
	is MenuMouseSelection
	where self.type == "selection"
	i: integer
end

local mouse_selection = {
	MenuMouseSelection = MenuMouseSelection,
	Grid = Grid,
	List = List,
}

function mouse_selection.grid(
	x: integer,
	y: integer,
	on_lmb_command: menu_types.MenuCommand,
	on_rmb_command: menu_types.MenuCommand
): MenuMouseSelection
	local self: Grid =  {
		type = "grid",
		x = x,
		y = y,
		on_lmb_command = on_lmb_command,
		on_rmb_command = on_rmb_command,
	}
	return self
end

function mouse_selection.list(
	i: integer,
	on_lmb_command: menu_types.MenuCommand,
	on_rmb_command: menu_types.MenuCommand
): MenuMouseSelection
	local self: List =  {
		type = "selection",
		i = i,
		on_lmb_command = on_lmb_command,
		on_rmb_command = on_rmb_command,
	}
	return self
end

local interface SerializedMenuState
	type: MenuContainerType
	children: {string: SerializedMenuState}
end

local type SerializedMenuData = {string: any}

local interface SerializedMenu
	state: SerializedMenuState
	data: SerializedMenuData
end

local interface MenuNode
	id: string
	-- note: passing contexts are only really needed for event handlers.  consider moving the handling to menu_manager level with a signal
    update_joy: function(self, Joypad, game_context: GameContext, menu_ctx: MenuContext): MenuSignal
    update_mouse: function(self, Mouse, MenuMouseSelection, game_context: GameContext, menu_ctx: MenuContext): MenuSignal
    serialize: function(self): SerializedMenu
    deserialize: function(self, state: SerializedMenuState, data: SerializedMenuData)
end

local interface MenuLeaf
	is MenuNode
    type: MenuLeafType
--- @return next state
end

local interface MenuContainer
	is MenuNode
    type: MenuContainerType
    get_focused_leaf: function(self, game_context: GameContext, menu_ctx: MenuContext): MenuLeaf
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
	SerializedMenu = SerializedMenu,
	SerializedMenuState = SerializedMenuState,
	SerializedMenuData = SerializedMenuData,
	

    mouse_selection = mouse_selection,

    menu_signal = menu_signal,
}

return menu_cursor
