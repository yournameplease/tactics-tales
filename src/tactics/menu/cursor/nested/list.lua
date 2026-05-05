---@brief
--- Implements a menu cursor for navigating a 1D list of child menu nodes,
--- supporting both column (vertical) and row (horizontal) layouts.

local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal
local lists = require("src.tactics.util.lists")
local maps = require("src.tactics.util.maps")

---@alias NestedMenuType "row"|"column"

---@class SerializedNestedMenuNodeState : SerializedMenuState
---@field type "list"
---@field i integer Focused child index at serialization time.

---@class NestedMenuNode : MenuContainer
---@field type "list"
---@field i integer 1-based index of the currently focused child.
---@field children MenuNode[]
---@field direction NestedMenuType Navigation axis for joypad input.
---@field wrap boolean When true, navigating past the end wraps to the beginning.
local NestedMenuNode = {}
NestedMenuNode.__index = NestedMenuNode

---@class NestedMenuDefinition : MenuContainerDefinition
---@field type "list"
---@field get_children fun(game_ctx: GameContext, menu_ctx: MenuContext): MenuNodeDefinition[]
---@field wrap boolean
---@field direction NestedMenuType
local NestedMenuDefinition = {}
NestedMenuDefinition.__index = NestedMenuDefinition

local nested_menu = {
    NestedMenuNode = NestedMenuNode,
    NestedMenuDefinition = NestedMenuDefinition,
}

--- Advance the focused child index by one, wrapping or clamping as configured.
function NestedMenuNode:increment_focus_index()
    log.debug("incrementing", self.i, #self.children)
    local new_i = self.i + 1
    if self.wrap then
        self.i = (new_i - 1) % #self.children + 1
    else
        self.i = math.max(1, math.min(new_i, #self.children))
    end
end

--- Retreat the focused child index by one, wrapping or clamping as configured.
function NestedMenuNode:decrement_focus_index()
    local new_i = self.i - 1
    if self.wrap then
        self.i = (new_i - 1) % #self.children + 1
    else
        self.i = math.max(1, math.min(new_i, #self.children))
    end
end

--- Return the currently focused child node.
---@return MenuNode
function NestedMenuNode:get_selected_child()
    return self.children[self.i]
end

--- Return the focused leaves beneath this node by delegating to the active child.
---@param menu_ctx MenuContext
---@param game_ctx GameContext
---@return MenuNode[]
function NestedMenuNode:get_focused_leaves(menu_ctx, game_ctx)
    local child = self:get_selected_child()
    if child.type == "selection" or child.type == "button" then
        return { child }
    else
        return child:get_focused_leaves(menu_ctx, game_ctx)
    end
end

--- Handle joypad input, propagating to focused leaves then shifting focus between children.
---@param joy Joypad
---@param commands string[]
---@param menu_ctx MenuContext
---@param game_ctx GameContext
---@return MenuSignal
function NestedMenuNode:update_joy(joy, commands, menu_ctx, game_ctx)
    local child = self:get_selected_child()

    local signal = menu_signal.ignored()
    if child ~= nil then
        signal = child:update_joy(joy, commands, menu_ctx, game_ctx)
    end
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
    end

    if self.i == old_i then
        return menu_signal.ignored()
    else
        self.children[old_i]:lose_focus()
        self.children[self.i]:refresh_focus()
        return menu_signal.consumed()
    end
end

--- Handle mouse input by propagating to focused leaves.
---@param mouse Mouse
---@param selection MenuMouseSelection
---@param menu_ctx MenuContext
---@param game_ctx GameContext
---@return MenuSignal
function NestedMenuNode:update_mouse(mouse, selection, menu_ctx, game_ctx)
    local focused_leaves = self:get_focused_leaves(menu_ctx, game_ctx)

    for _, leaf in ipairs(focused_leaves) do
        local sig = leaf:update_mouse(mouse, selection, menu_ctx, game_ctx)
        if sig.type ~= "ignored" then
            return sig
        end
    end

    return menu_signal.ignored()
end

--- Remove focus from this node and the currently focused child.
function NestedMenuNode:lose_focus()
    self.has_focus = false
    if self.i > 0 and self.i <= #self.children then
        self.children[self.i]:lose_focus()
    end
end

--- Restore focus to this node and the currently focused child.
function NestedMenuNode:refresh_focus()
    self.has_focus = true
    if self.i > 0 and self.i <= #self.children then
        self.children[self.i]:refresh_focus()
    end
end

--- Claim focus, updating the focused index to match the child that initiated the claim.
---@param _selection MenuMouseSelection?
---@param child MenuNode?
function NestedMenuNode:claim_focus(_selection, child)
    self.has_focus = true
    if child ~= nil then
        for i, c in ipairs(self.children) do
            if c == child then
                self.i = i
            else
                c:lose_focus()
            end
        end
    end
    if self.parent then
        self.parent:claim_focus(nil, self)
    end
end

--- List nodes do not handle commands directly; always returns ignored.
---@param _command string
---@param _menu_ctx MenuContext
---@param _game_ctx GameContext
---@return MenuSignal
function NestedMenuNode:handle_command(_command, _menu_ctx, _game_ctx)
    return menu_signal.ignored()
end

--- Serialize the focused index and all child states.
---@return SerializedMenu
function NestedMenuNode:serialize()
    ---@type SerializedNestedMenuNodeState
    local state = {
        type = "list",
        i = self.i,
        children = {},
    }
    ---@type SerializedMenu
    local out = {
        state = state,
        data = {},
    }

    for _, child in ipairs(self.children) do
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

--- Restore the focused index and child states from serialized data.
---@param state SerializedMenuState?
---@param data table<string, any>
function NestedMenuNode:deserialize(state, data)
    if state ~= nil and state.type == "list" then
        ---@cast state SerializedNestedMenuNodeState
        self.i = state.i
    end
    for _, child in ipairs(self.children) do
        child:deserialize(state and state.children[child.id] or nil, data)
    end
end

--- Recompute derived state for all children.
---@param game_ctx GameContext
---@param menu_ctx MenuContext
function NestedMenuNode:recompute(game_ctx, menu_ctx)
    for _, child in ipairs(self.children) do
        child:recompute(game_ctx, menu_ctx)
    end
end

--- Build a NestedMenuNode from this definition.
---@param parent MenuNode?
---@param game_ctx GameContext
---@param menu_ctx MenuContext
---@param menu_state MenuState
---@return MenuNode
function NestedMenuDefinition:to_cursor(parent, game_ctx, menu_ctx, menu_state)
    local cursor = {
        type = "list",
        parent = parent,
        i = 1,
        has_focus = false,
    }
    setmetatable(cursor, {
        __index = function(_, k)
            if NestedMenuNode[k] then
                return NestedMenuNode[k]
            end
            return self[k]
        end
    })
    cursor.children = lists.map(function(def)
        return def:to_cursor(cursor, game_ctx, menu_ctx, menu_state)
    end)(self.get_children(game_ctx, menu_ctx))
    return cursor
end

--- Create a vertical column list definition builder.
---@param id string
---@param get_children fun(game_ctx: GameContext, menu_ctx: MenuContext): MenuNodeDefinition[]
---@return NestedMenuDefinition
function nested_menu.column(id, get_children)
    return setmetatable({
        id = id,
        get_children = get_children,
        direction = "column",
    }, { __index = NestedMenuDefinition })
end

--- Create a horizontal row list definition builder.
---@param id string
---@param get_children fun(game_ctx: GameContext, menu_ctx: MenuContext): MenuNodeDefinition[]
---@return NestedMenuDefinition
function nested_menu.row(id, get_children)
    return setmetatable({
        id = id,
        get_children = get_children,
        direction = "row",
    }, { __index = NestedMenuDefinition })
end

return nested_menu
