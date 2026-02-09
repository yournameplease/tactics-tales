---@brief
--- Implements a menu cursor for buttons, used for event handlers
--- and menu advances

local point = require("src.tactics.util.point")
local Point = point.Point
local menu_cursor = require("src.tactics.menu.menu_cursor")
local MenuHandler = menu_cursor.MenuHandler
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
    is menu_cursor.MenuCursor
    where self.type == "button"
    -- from definition

	text: string
	value: string
    -- set_selected_context: function(ButtonCursor, GameContext, MenuContext)
    -- validator: function(ButtonCursor, GameContext, MenuContext): boolean
    next_state: menu_types.MenuStep
    select_handler: function(self, GameContext, MenuContext)
    back_handler: function(self, GameContext, MenuContext)
end

local record ButtonDefinition
    is menu_cursor.MenuStepDefinition
    where self.type == "button"

	text: string
	value: string
    -- set_selected_context: function(self, GameContext, MenuContext)
    -- validator: function(ButtonCursor, GameContext, MenuContext): boolean
    next_state: menu_types.MenuStep
    select_handler: function(ButtonCursor, GameContext, MenuContext)
    back_handler: function(ButtonCursor, GameContext, MenuContext)
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

function ButtonCursor:update_joy(joy: Joypad)
end

function ButtonCursor:update_mouse(
    _mouse: Mouse,
    hovered: mouse_menu_selection.MenuMouseSelection
)
end

function ButtonCursor:handle_select(
    game_ctx: GameContext,
    menu_ctx: MenuContext,
    menu_state: menu_types.MenuState
): string 
    local validation = self:validator(game_ctx, menu_ctx)
    if not validation then return end

    self:set_selected_context(game_ctx, menu_ctx)

    if self.select_handler then
        self:select_handler(game_ctx, menu_ctx)
    end
    return self.next_state 
end

function ButtonCursor:handle_back(
    game_ctx: GameContext,
    menu_ctx: MenuContext
) 
    if self.back_handler then
        self:back_handler(game_ctx, menu_ctx)
    end
end

function ButtonDefinition:to_cursor(
    game_ctx: GameContext,
    menu_ctx: MenuContext,
    menu_state: menu_types.MenuState
): menu_cursor.MenuCursor
    local cursor: ButtonCursor = {
        type = "button",
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

function button.builder(): ButtonDefinition
	return setmetatable({},{
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
	select_handler: function(ButtonCursor, GameContext, MenuContext)
): ButtonDefinition
	self.select_handler = select_handler
	return self
end

function ButtonDefinition:handle_back(
	back_handler: function(ButtonCursor, GameContext, MenuContext)
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
	value: string
): ButtonDefinition
	self.value = value
	return self
end

return button

