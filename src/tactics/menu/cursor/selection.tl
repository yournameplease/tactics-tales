---@brief
--- Implements a menu cursor for navigating a 1D list of options,
--- supporting both horizontal and vertical lists.

local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal
local SerializedMenu = menu_cursor.SerializedMenu
local MenuSignal = menu_signal.MenuSignal
local menu_types = require("src.tactics.menu.types")
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext
local lists = require("src.tactics.util.lists")
local input_service = require("src.tactics.joypad")
local Joypad = require("src.tactics.joypad").Joypad
local Mouse = input_service.Mouse
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection

global enum SelectionDirection
    "vertical"
    "horizontal"
end

local record SelectionMenuOption
    text: string
    value: any
end

local record SelectionMenuNode
    is menu_cursor.MenuLeaf
    where self.type == "selection"
    i: integer
    options: { SelectionMenuOption }

    -- from definition
    label: string
    key: string
    direction: SelectionDirection
    wrap: boolean
end

function SelectionMenuNode:get_selected_value(): any
	return self.options[self.i].value
end

function SelectionMenuNode:get_selected_text(): string
	return self.options[self.i].text
end

local record SelectionMenuDefinition
    is menu_cursor.MenuLeafDefinition
    where self.type == "selection"

    label: string
    key: string
    get_options: function(GameContext, MenuContext): {SelectionMenuOption}
    wrap: boolean
    direction: SelectionDirection
end

local selection_cursor = {
    SelectionMenuOption = SelectionMenuOption,
    SelectionMenuNode = SelectionMenuNode,
    SelectionMenuDefinition = SelectionMenuDefinition,
}

function selection_cursor.row(
	id: string
): SelectionMenuDefinition
	return setmetatable({
		id = id,
		direction = "horizontal",
	},{
		__index = SelectionMenuDefinition
	})
end

function SelectionMenuDefinition:with_label(
	label: string
): SelectionMenuDefinition
	self.label = label
	return self
end

function SelectionMenuDefinition:with_key(
	key: string
): SelectionMenuDefinition
	self.key = key
	return self
end

function SelectionMenuDefinition:with_options(
	options: function(GameContext, MenuContext): {SelectionMenuOption}
): SelectionMenuDefinition
	self.get_options = options
	return self
end

local get_yes_no_options = function(_game_ctx: GameContext, _menu_context: MenuContext): {SelectionMenuOption}
    return {{
		text = "YES",
		value = true,
    }, {
		text = "NO",
		value = false,
	}}
end

function SelectionMenuDefinition:with_yes_no_options(): SelectionMenuDefinition
	self.get_options = get_yes_no_options
	return self
end

function SelectionMenuDefinition:with_static_options(
	options: {any}
): SelectionMenuDefinition
	self.get_options = function(_game_ctx: GameContext, _menu_context: MenuContext): {SelectionMenuOption}
		return lists.map(function(o: any): SelectionMenuOption
			return {
				text = tostring(o),
				value = o,
			}
		end)(options)
	end
	return self
end

function SelectionMenuDefinition:with_precomputed_options(
	options: {SelectionMenuOption}
): SelectionMenuDefinition
	self.get_options = function(_game_ctx: GameContext, _menu_context: MenuContext): {SelectionMenuOption}
		return options
	end
	return self
end

function SelectionMenuNode:increment_selection()
    local new_i = self.i + 1
    if self.wrap then
        self.i = (new_i - 1) % #self.options + 1
    else
        self.i = pt.mid(1, new_i, #self.options)
    end
end

function SelectionMenuNode:decrement_selection()
    local new_i = self.i - 1
    if self.wrap then
        self.i = (new_i - 1) % #self.options + 1
    else
        self.i = pt.mid(1, new_i, #self.options)
    end
end

function SelectionMenuNode:update_joy(
	joy: Joypad
): MenuSignal
    if self.direction == "vertical" then
		if joy.dyp == 1 then
			self:increment_selection()
			return menu_signal.consumed()
		elseif joy.dyp == -1 then
			self:decrement_selection()
			return menu_signal.consumed()
		end
    elseif self.direction == "horizontal" then
		if joy.dxp == 1 then
			self:increment_selection()
			return menu_signal.consumed()
		elseif joy.dxp == -1 then
			self:decrement_selection()
			return menu_signal.consumed()
		end
    else
        unexpected(self.direction)
    end
	return menu_signal.ignored()
end

function SelectionMenuNode:claim_focus(
    _selection: mouse_menu_selection.MenuMouseSelection,
    _child: menu_cursor.MenuNode
)
	if self.parent then
		self.parent:claim_focus(nil, self)
	end
end

function SelectionMenuNode:handle_command(
    command: menu_types.MenuCommand
): MenuSignal
	if command == "increment_selection" then
		self:increment_selection()
		return menu_signal.consumed()
	end
	if command == "decrement_selection" then
		self:decrement_selection()
		return menu_signal.consumed()
	end

    return menu_signal.ignored()
end

function SelectionMenuNode:serialize(): SerializedMenu
	return {
		state = nil,
		data = {
			[self.key] = self:get_selected_value()
		},
	}
end

function SelectionMenuNode:deserialize(_state: menu_cursor.SerializedMenuState, data: {string: any}) 
	local value = data[self.key]
	if value then
		for i,opt in ipairs(self.options) do
			if opt.value == value then
				self.i = i
			end
		end
	end
end

function SelectionMenuDefinition:to_cursor(
	parent: menu_cursor.MenuNode,
	game_ctx: GameContext,
	menu_ctx: MenuContext,
	_: menu_types.MenuState
): menu_cursor.MenuNode
    local cursor: SelectionMenuNode = {
        type = "selection",
        parent = parent,
        i = 1,
        options = self.get_options(game_ctx, menu_ctx),
    }
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (SelectionMenuNode as {string: any})[k] then
                return (SelectionMenuNode as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

return selection_cursor

