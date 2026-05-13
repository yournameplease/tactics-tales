---@brief
--- Defines the core interfaces and types for menu cursors, which
--- handle user navigation within a menu.

---@alias MenuSignalType "navigate"|"finish"|"call_handler"|"on_change"|"ignored"|"consumed"|"back"

---@class MenuSignal Abstract base for all menu signals.
---@field type MenuSignalType

---@class MenuSignalBack : MenuSignal
---@field type "back"
---@field target? string Step to back all the way to, if provided.

---@class MenuSignalConsumed : MenuSignal
---@field type "consumed"

---@class MenuSignalIgnored : MenuSignal
---@field type "ignored"

---@class MenuSignalNavigate : MenuSignal
---@field type "navigate"
---@field target string Target step to navigate to.

---@class MenuSignalFinish : MenuSignal
---@field type "finish"

---@class MenuSignalCallHandler : MenuSignal
---@field type "call_handler"
---@field handler string Handler ID to invoke.
---@field value any Typically the value of the button that triggered the signal.
---@field then_navigate_to? string Step to navigate to after the handler runs.
---@field then_finish? boolean When true, finish the menu after the handler.
---@field then_back? boolean When true, go back after the handler.
---@field then_back_to? string When set, go back to this named step after the handler.

---@class MenuSignalOnChange : MenuSignal
---@field type "on_change"
---@field handler string Handler ID to invoke.
---@field value any The newly selected value.

---@alias MenuLeafType "selection"|"button"

---@alias MenuContainerType "list"|"grid"

---@alias CursorType "leaf"|"list"|"grid"

---@class SerializedMenuState Abstract base for serialized subtree state.
---@field type MenuContainerType
---@field children table<string, SerializedMenuState> Serialized states keyed by child node ID.

---@class SerializedMenu Complete serialized state of one menu node and its descendants.
---@field state? SerializedMenuState Structural state; nil for leaf nodes with no position.
---@field data table<string, any> Flat key-value data contributed by leaf nodes.

---@class MenuNode Abstract base for all menu node instances.
---@field id string Unique node identifier within the menu.
---@field parent? MenuNode Parent node; nil for the root.
---@field has_focus boolean
---@field type string Discriminant: "button", "selection", "list", or "grid".
---@field value? any Value field used by button nodes and injected by grids.
---@field update_joy fun(self: MenuNode, joy: Joypad, commands: string[], menu_ctx: MenuContext, game_ctx: GameContext): MenuSignal
---@field update_mouse fun(self: MenuNode, mouse: Mouse, selection: MenuMouseSelection, menu_ctx: MenuContext, game_ctx: GameContext): MenuSignal
---@field handle_command fun(self: MenuNode, command: string, menu_ctx: MenuContext, game_ctx: GameContext): MenuSignal
---@field get_focused_leaves fun(self: MenuNode, menu_ctx: MenuContext, game_ctx: GameContext): MenuLeaf[]
---@field lose_focus fun(self: MenuNode)
---@field refresh_focus fun(self: MenuNode)
---@field claim_focus fun(self: MenuNode, selection: MenuMouseSelection?, child: MenuNode?)
---@field serialize fun(self: MenuNode): SerializedMenu
---@field deserialize fun(self: MenuNode, state: SerializedMenuState?, data: table<string, any>)
---@field recompute fun(self: MenuNode, game_ctx: GameContext, menu_ctx: MenuContext)

---@class MenuLeaf : MenuNode Abstract base for leaf nodes (button, selection).
---@field type MenuLeafType
---@field keyboard_handler? string MenuHandlerId called with typed text when this leaf is focused.

---@class MenuContainer : MenuNode Abstract base for container nodes (list, grid).
---@field type MenuContainerType

---@class MenuNodeDefinition Abstract base for node build specs.
---@field id string
---@field to_cursor fun(self: MenuNodeDefinition, parent: MenuNode?, game_ctx: GameContext, menu_ctx: MenuContext, menu_state: MenuState): MenuNode

---@class MenuLeafDefinition : MenuNodeDefinition
---@field type MenuLeafType

---@class MenuContainerDefinition : MenuNodeDefinition
---@field type MenuContainerType

---@class MenuMouseSelection Abstract base for mouse hover targets.
---@field type CursorType
---@field node MenuNode The node under the cursor.
---@field on_lmb_command? string Command issued on left-click.
---@field on_rmb_command? string Command issued on right-click.

---@class GridMouseSelection : MenuMouseSelection
---@field type "grid"
---@field x integer Grid column under the cursor (0-indexed).
---@field y integer Grid row under the cursor (0-indexed).

---@class ListMouseSelection : MenuMouseSelection
---@field type "list"
---@field i integer List index under the cursor (1-indexed).

---@class LeafMouseSelection : MenuMouseSelection
---@field type "leaf"
---@field i? integer

local menu_signal = {}

--- Create a "back" signal to navigate to the previous step.
---@param target? string Step to back all the way to; if nil, goes back one step.
---@return MenuSignalBack
function menu_signal.back(target)
    return { type = "back", target = target }
end

--- Create a "consumed" signal indicating input was handled but produced no action.
---@return MenuSignal
function menu_signal.consumed()
    return { type = "consumed" }
end

--- Create an "ignored" signal indicating input was not handled.
---@return MenuSignal
function menu_signal.ignored()
    return { type = "ignored" }
end

--- Create a "finish" signal to close the active menu.
---@return MenuSignal
function menu_signal.finish()
    return { type = "finish" }
end

--- Create a "navigate" signal to transition to a named step.
---@param target string Target step ID.
---@return MenuSignal
function menu_signal.navigate(target)
    ---@type MenuSignalNavigate
    local out = {
        type = "navigate",
        target = target,
    }
    return out
end

--- Create a "call_handler" signal, optionally with post-handling navigation.
---@param handler string Handler ID to invoke.
---@param value any Value passed to the handler; typically the button's value.
---@return MenuSignalCallHandler
function menu_signal.call_handler(handler, value)
    ---@type MenuSignalCallHandler
    local out = {
        type = "call_handler",
        handler = handler,
        value = value,
    }
    return out
end

--- Create an "on_change" signal emitted when a selection widget changes value.
---@param handler string Handler ID to invoke.
---@param value any The newly selected value.
---@return MenuSignalOnChange
function menu_signal.on_change(handler, value)
    ---@type MenuSignalOnChange
    return { type = "on_change", handler = handler, value = value }
end

local mouse_selection = {}

--- Create a grid mouse selection at the given tile coordinates.
---@param x integer 0-indexed grid column.
---@param y integer 0-indexed grid row.
---@param node MenuNode Node under the cursor.
---@param on_lmb_command string? Command issued on left-click.
---@param on_rmb_command string? Command issued on right-click.
---@return MenuMouseSelection
function mouse_selection.grid(x, y, node, on_lmb_command, on_rmb_command)
    ---@type GridMouseSelection
    local self = {
        type = "grid",
        x = x,
        y = y,
        node = node,
        on_lmb_command = on_lmb_command,
        on_rmb_command = on_rmb_command,
    }
    return self
end

--- Create a list mouse selection for a specific list index.
---@param i integer 1-indexed list position under the cursor.
---@param node MenuNode Node under the cursor.
---@param on_lmb_command string?
---@param on_rmb_command string?
---@return MenuMouseSelection
function mouse_selection.list(i, node, on_lmb_command, on_rmb_command)
    ---@type ListMouseSelection
    local self = {
        type = "list",
        i = i,
        node = node,
        on_lmb_command = on_lmb_command,
        on_rmb_command = on_rmb_command,
    }
    return self
end

--- Create a leaf mouse selection.
---@param node MenuNode Node under the cursor.
---@param on_lmb_command string?
---@param on_rmb_command string?
---@return MenuMouseSelection
function mouse_selection.leaf(node, on_lmb_command, on_rmb_command)
    ---@type LeafMouseSelection
    local self = {
        type = "leaf",
        node = node,
        on_lmb_command = on_lmb_command,
        on_rmb_command = on_rmb_command,
    }
    return self
end

local menu_cursor = {
    mouse_selection = mouse_selection,
    menu_signal = menu_signal,
}

return menu_cursor
