
---@brief
--- Implements a menu cursor for navigating a 1D list of options,
--- supporting both horizontal and vertical lists.

local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal
local MenuSignal = menu_signal.MenuSignal
local SerializedMenu = menu_cursor.SerializedMenu
local SerializedMenuState = menu_cursor.SerializedMenuState
local MenuNodeDefinition = menu_cursor.MenuNodeDefinition
local MenuNode = menu_cursor.MenuNode
local menu_types = require("src.tactics.menu.types")
local menu_context = require("src.tactics.menu.menu_context")
local MenuContext = menu_context.MenuContext
local GameContext = menu_context.GameContext
local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")
local input_service = require("src.tactics.joypad")
local Joypad = require("src.tactics.joypad").Joypad
local Mouse = input_service.Mouse
local mouse_menu_selection = require("src.tactics.menu.menu_cursor").mouse_selection

local enum NestedMenuType
    "row"
    "column"
end

local record NestedMenuNode
    is menu_cursor.MenuContainer
    where self.type == "list"
    i: integer
    children: { menu_cursor.MenuNode }

    -- from definition
    direction: NestedMenuType
    wrap: boolean
end

local record NestedMenuDefinition
    is menu_cursor.MenuContainerDefinition
    where self.type == "list"
    get_children: function(GameContext, MenuContext): {menu_cursor.MenuNodeDefinition}
    wrap: boolean
    direction: NestedMenuType
end

local nested_menu = {
    NestedMenuNode = NestedMenuNode,
    NestedMenuDefinition = NestedMenuDefinition,
}

function NestedMenuNode:increment_focus_index()
    local new_i = self.i + 1
    if self.wrap then
        self.i = (new_i - 1) % #self.children + 1
    else
        self.i = pt.mid(1, new_i, #self.children)
    end
end

function NestedMenuNode:decrement_focus_index()
    local new_i = self.i - 1
    if self.wrap then
        self.i = (new_i - 1) % #self.children + 1
    else
        self.i = pt.mid(1, new_i, #self.children)
    end
end

function NestedMenuNode:update_joy(
	joy: Joypad,
    game_ctx: GameContext,
    menu_ctx: MenuContext
): MenuSignal
	local signal = self:get_focused_leaf():update_joy(joy, game_ctx, menu_ctx)
    if signal.type ~= "ignored" then return signal end

    if self.direction == "column" then
		if joy.dyp == 1 then
			self:increment_focus_index()
			return menu_signal.consumed()
		elseif joy.dyp == -1 then
			self:decrement_focus_index()
			return menu_signal.consumed()
		end
    elseif self.direction == "row" then
		if joy.dxp == 1 then
			self:increment_focus_index()
			return menu_signal.consumed()
		elseif joy.dxp == -1 then
			self:decrement_focus_index()
			return menu_signal.consumed()
		end
    else
        unexpected(self.direction)
    end
    return menu_signal.ignored()
end

function NestedMenuNode:update_mouse(
    mouse: Mouse,
    hovered: mouse_menu_selection.MenuMouseSelection,
    game_ctx: GameContext,
    menu_ctx: MenuContext
): MenuSignal
    if hovered == nil then return menu_signal.ignored() end

	local signal = self:get_focused_leaf():update_mouse(mouse, hovered, game_ctx, menu_ctx)
    if signal.type ~= "ignored" then return signal end

    if hovered is mouse_menu_selection.List then
        if hovered.i > 0 and hovered.i <= #self.children then
            self.i = hovered.i
        end
    end
    return menu_signal.ignored()
end

local record SerializedNestedMenuNodeState
	is SerializedMenuState
	where self.type == "list"
	i: integer
end

function NestedMenuNode:serialize(): SerializedMenu
	local state: SerializedNestedMenuNodeState = {
		type = "list",
		i = self.i,
		children = {},
	}
	local out: SerializedMenu = {
		state = state,
		data = {},
	}

	for _,child in ipairs(self.children) do
		local child_out = child:serialize()

		if child_out.data then
			maps.merge(out.data, child_out.data)
		end

		if child_out.state and child.id then
			out.state.children[child.id] = child_out.state
		end
	end

	return out
end

function NestedMenuDefinition:to_cursor(game_ctx: GameContext, menu_ctx: MenuContext, menu_state: menu_types.MenuState): menu_cursor.MenuNode
    local cursor: NestedMenuNode = {
        type = "list",
        i = 1,
        children = lists.map(function(def: MenuNodeDefinition): MenuNode
            return def:to_cursor(game_ctx, menu_ctx, menu_state)
        end)(self.get_children(game_ctx, menu_ctx)),
    }
    return setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (NestedMenuNode as {string: any})[k] then
                return (NestedMenuNode as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
end

--- builders

function nested_menu.column(
	get_children: function(game_ctx: GameContext, menu_ctx: MenuContext): {MenuNodeDefinition}
): NestedMenuDefinition
	return setmetatable({
	    get_children = get_children,
	    direction = "column",
	},{
	    __index = NestedMenuDefinition
	})
end

return nested_menu
