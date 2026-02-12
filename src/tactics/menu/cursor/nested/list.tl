
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
local Joypad = require("src.tactics.joypad").Joypad
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

function NestedMenuNode:get_selected_child(): menu_cursor.MenuNode
	return self.children[self.i]
end

function NestedMenuNode:get_focused_leaf(): menu_cursor.MenuLeaf
	local child = self:get_selected_child()
	if child is menu_cursor.MenuLeaf then
		return child
	elseif child is menu_cursor.MenuContainer then
		return child:get_focused_leaf()
	end
end

function NestedMenuNode:update_joy(
	joy: Joypad
): MenuSignal
	local signal = self:get_focused_leaf():update_joy(joy)
    if signal ~= nil and signal.type ~= "ignored" then return signal end
    local old_i = self.i

    if self.direction == "column" then
		if joy.dyp == 1 then
			self:increment_focus_index()
		elseif joy.dyp == -1 then
			self:decrement_focus_index()
		end
    elseif self.direction == "row" then
		if joy.dxp == 1 then
			self:increment_focus_index()
		elseif joy.dxp == -1 then
			self:decrement_focus_index()
		end
    else
        unexpected(self.direction)
    end

	if self.i == old_i then
	    return menu_signal.ignored()
	else
		return menu_signal.consumed()
	end
end

function NestedMenuNode:claim_focus(
    _selection: mouse_menu_selection.MenuMouseSelection,
    child: menu_cursor.MenuNode
)
	if child ~= nil then
		for i,c in ipairs(self.children) do
			if c == child then
				self.i = i
			end
		end
	end
	if self.parent then
		self.parent:claim_focus(nil, self)
	end
end

function NestedMenuNode:handle_command(
    _command: menu_types.MenuCommand
): MenuSignal
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
			maps.add_all(out.data, child_out.data)
		end

		if child_out.state and child.id then
			out.state.children[child.id] = child_out.state
		end
	end

	return out
end

function NestedMenuNode:deserialize(state: menu_cursor.SerializedMenuState, data: {string: any}) 
	if state ~= nil and state is SerializedNestedMenuNodeState then
		self.i = state.i
	end
	for _,child in ipairs(self.children) do
		child:deserialize(state and state.children[child.id] or nil, data)
	end
end

function NestedMenuDefinition:to_cursor(
	parent: menu_cursor.MenuNode,
	game_ctx: GameContext,
	menu_ctx: MenuContext,
	menu_state: menu_types.MenuState
): menu_cursor.MenuNode
    local cursor: NestedMenuNode = {
        type = "list",
        parent = parent,
        i = 1,
    }
    setmetatable(cursor, { __index = function(_: any, k: string): any 
            if (NestedMenuNode as {string: any})[k] then
                return (NestedMenuNode as {string: any})[k]
            end
            return (self as {string: any})[k]
        end
        })
	cursor.children = lists.map(function(def: MenuNodeDefinition): MenuNode
            return def:to_cursor(cursor, game_ctx, menu_ctx, menu_state)
        end)(self.get_children(game_ctx, menu_ctx))
    return cursor
end

--- builders

function nested_menu.column(
	id: string,
	get_children: function(game_ctx: GameContext, menu_ctx: MenuContext): {MenuNodeDefinition}
): NestedMenuDefinition
	return setmetatable({
		id = id,
	    get_children = get_children,
	    direction = "column",
	},{
	    __index = NestedMenuDefinition
	})
end

function nested_menu.row(
	id: string,
	get_children: function(game_ctx: GameContext, menu_ctx: MenuContext): {MenuNodeDefinition}
): NestedMenuDefinition
	return setmetatable({
		id = id,
	    get_children = get_children,
	    direction = "row",
	},{
	    __index = NestedMenuDefinition
	})
end

return nested_menu
