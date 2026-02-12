---@brief
--- Implements a menu cursor for buttons, used for event handlers
--- and menu advances

local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal
local MenuSignal = menu_signal.MenuSignal
local SerializedMenu = menu_cursor.SerializedMenu
local menu_types = require("src.tactics.menu.types")
local input_service = require("src.tactics.joypad")
local Joypad = input_service.Joypad
local Mouse = input_service.Mouse
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext

local record MenuTileHighlight
    reachable: boolean
    valid_selection: boolean
    can_attack: boolean
end

local record ButtonCursor
    is menu_cursor.MenuLeaf
    where self.type == "button"
    -- from definition

	text: string
	value: any
    -- set_selected_context: function(ButtonCursor, GameContext, MenuContext)
    -- validator: function(ButtonCursor, GameContext, MenuContext): boolean
    next_state: menu_types.MenuStep
    select_handler: menu_types.MenuHandlerId
    back_handler: menu_types.MenuHandlerId
end

local record ButtonDefinition
    is menu_cursor.MenuLeafDefinition
    where self.type == "button"

	text: string
	value: any
    -- set_selected_context: function(self, GameContext, MenuContext)
    -- validator: function(ButtonCursor, GameContext, MenuContext): boolean
    next_state: menu_types.MenuStep
    select_handler: menu_types.MenuHandlerId
    back_handler: menu_types.MenuHandlerId
end

local button = {
    MenuTileHighlight = MenuTileHighlight,
    ButtonCursor = ButtonCursor,
    ButtonDefinition = ButtonDefinition,
}

function button.definition(
    props: ButtonDefinition
): ButtonDefinition
    props.type = "button"
    return setmetatable(props, { __index = ButtonDefinition })
end

function ButtonCursor:update_joy(
	joy: Joypad
): MenuSignal
	if self.select_handler ~= nil or self.next_state ~= nil then
		if joy.ap then
			if self.select_handler ~= nil then
				local signal = menu_signal.call_handler(self.select_handler, self.value)
				if self.next_state ~= nil then
					signal.then_navigate_to = self.next_state
				end
				return signal
			end
			if self.next_state ~= nil then
				return menu_signal.navigate(self.next_state)
			end
			return menu_signal.consumed()
		end
	end
	if self.back_handler ~= nil then
		if joy.bp then
			return menu_signal.call_handler(self.back_handler, self.value)
		end
	end
	return menu_signal.ignored()
end

function ButtonCursor:claim_focus(
    _selection: mouse_menu_selection.MenuMouseSelection,
    _child: menu_cursor.MenuNode
)
	if self.parent then
		self.parent:claim_focus(nil, self)
	end
end

function ButtonCursor:handle_command(
    command: menu_types.MenuCommand
): MenuSignal
	if self.select_handler ~= nil or self.next_state ~= nil then
		if command == "button_primary" then
			if self.select_handler ~= nil then
				local signal = menu_signal.call_handler(self.select_handler, self.value)
				if self.next_state ~= nil then
					signal.then_navigate_to = self.next_state
				end
				return signal
			end
			if self.next_state ~= nil then
				return menu_signal.navigate(self.next_state)
			end
			return menu_signal.consumed()
		end
	end
	if self.back_handler ~= nil then
		if command == "button_secondary" then
			return menu_signal.call_handler(self.back_handler, self.value)
		end
	end
	return menu_signal.ignored()
end

function ButtonCursor:serialize(): SerializedMenu
	return {
		state = nil,
		data = {},
	}
end

function ButtonDefinition:to_cursor(
	parent: menu_cursor.MenuNode,
    _game_ctx: GameContext,
    _menu_ctx: MenuContext,
    _menu_state: menu_types.MenuState
): menu_cursor.MenuNode
    local cursor: ButtonCursor = {
        type = "button",
        parent = parent,
    }
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (ButtonCursor as {string: any})[k] then
                return (ButtonCursor as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

-- definition builder

function button.builder(id: string): ButtonDefinition
	return setmetatable({
		id = id,
	},{
		__index = ButtonDefinition
	})
end

function ButtonDefinition:advance_to(
	next_state: string
): ButtonDefinition
	self.next_state = next_state
	return self
end

function ButtonDefinition:handle_select(
	select_handler: menu_types.MenuHandlerId
): ButtonDefinition
	self.select_handler = select_handler
	return self
end

function ButtonDefinition:handle_back(
	back_handler: menu_types.MenuHandlerId
): ButtonDefinition
	self.back_handler = back_handler
	return self
end

function ButtonDefinition:with_text(
	text: string
): ButtonDefinition
	self.text = text
	return self
end

function ButtonDefinition:with_value(
	value: any
): ButtonDefinition
	self.value = value
	return self
end

return button

