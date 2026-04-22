---@brief
--- Implements a menu cursor for navigating a 1D list of options,
--- supporting both horizontal and vertical lists.

local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal
local lists = require("src.tactics.util.lists")

---@alias SelectionDirection "vertical"|"horizontal"

---@class SelectionMenuOption
---@field text string Display label.
---@field value any The value this option represents.
---@field description? string Optional human-readable description.

---@class SelectionMenuNode : MenuLeaf
---@field type "selection"
---@field i integer 1-based index of the currently selected option.
---@field options SelectionMenuOption[]
---@field label? string Optional label shown alongside the selection.
---@field description? string Optional human-readable description for the node.
---@field key? string Key used when serializing the selected value into menu data.
---@field direction SelectionDirection Axis along which joypad input moves the selection.
---@field wrap boolean When true, navigating past the end wraps to the beginning.
local SelectionMenuNode = {}
SelectionMenuNode.__index = SelectionMenuNode

---@class SelectionMenuDefinition : MenuLeafDefinition
---@field type "selection"
---@field label? string
---@field key? string Serialization key for the selected value.
---@field get_options fun(game_ctx: GameContext, menu_ctx: MenuContext): SelectionMenuOption[]
---@field wrap boolean
---@field direction SelectionDirection
local SelectionMenuDefinition = {}
SelectionMenuDefinition.__index = SelectionMenuDefinition

local selection_cursor = {
    SelectionMenuNode = SelectionMenuNode,
    SelectionMenuDefinition = SelectionMenuDefinition,
}

--- Return the value of the currently selected option.
---@return any
function SelectionMenuNode:get_selected_value()
    return self.options[self.i].value
end

--- Return the display text of the currently selected option.
---@return string
function SelectionMenuNode:get_selected_text()
    return self.options[self.i].text
end

--- Return the description of the currently selected option, or nil if none.
---@return string?
function SelectionMenuNode:get_selected_description()
    return self.options[self.i].description
end

--- Advance the selection by one step, wrapping or clamping as configured.
function SelectionMenuNode:increment_selection()
    local new_i = self.i + 1
    if self.wrap then
        self.i = (new_i - 1) % #self.options + 1
    else
        self.i = math.max(1, math.min(new_i, #self.options))
    end
end

--- Retreat the selection by one step, wrapping or clamping as configured.
function SelectionMenuNode:decrement_selection()
    local new_i = self.i - 1
    if self.wrap then
        self.i = (new_i - 1) % #self.options + 1
    else
        self.i = math.max(1, math.min(new_i, #self.options))
    end
end

--- Handle joypad input, incrementing or decrementing based on direction.
---@param joy Joypad
---@param _commands string[]
---@param _menu_ctx MenuContext
---@param _game_ctx GameContext
---@return MenuSignal
function SelectionMenuNode:update_joy(joy, _commands, _menu_ctx, _game_ctx)
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
    end
    return menu_signal.ignored()
end

--- Handle mouse input; selection nodes do not respond to mouse events.
---@param _mouse Mouse
---@param _selection MenuMouseSelection
---@param _menu_ctx MenuContext
---@param _game_ctx GameContext
---@return MenuSignal
function SelectionMenuNode:update_mouse(_mouse, _selection, _menu_ctx, _game_ctx)
    return menu_signal.ignored()
end

--- Remove focus from this node.
function SelectionMenuNode:lose_focus()
    self.has_focus = false
end

--- Restore focus to this node.
function SelectionMenuNode:refresh_focus()
    self.has_focus = true
end

--- Claim focus for this node and propagate to parent.
---@param _selection MenuMouseSelection?
---@param _child MenuNode
function SelectionMenuNode:claim_focus(_selection, _child)
    self.has_focus = true
    if self.parent then
        self.parent:claim_focus(nil, self)
    end
end

--- Dispatch an explicit increment_selection or decrement_selection command.
---@param command string MenuCommand value.
---@param _menu_ctx MenuContext
---@param _game_ctx GameContext
---@return MenuSignal
function SelectionMenuNode:handle_command(command, _menu_ctx, _game_ctx)
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

--- Return the focused leaves; for a leaf node, that is itself.
---@param _menu_ctx MenuContext
---@param _game_ctx GameContext
---@return MenuNode[]
function SelectionMenuNode:get_focused_leaves(_menu_ctx, _game_ctx)
    return { self }
end

--- Serialize the currently selected value under this node's key.
---@return SerializedMenu
function SelectionMenuNode:serialize()
    return {
        state = nil,
        data = {
            [self.key] = self:get_selected_value()
        },
    }
end

--- Restore the selection from serialized data by matching option values.
---@param _state SerializedMenuState?
---@param data table<string, any>
function SelectionMenuNode:deserialize(_state, data)
    local value = data[self.key]
    if value ~= nil then
        for i, opt in ipairs(self.options) do
            if opt.value == value then
                self.i = i
            end
        end
    end
end

--- Recompute derived state (no-op for selection nodes).
---@param _game_ctx GameContext
---@param _menu_ctx MenuContext
function SelectionMenuNode:recompute(_game_ctx, _menu_ctx)
end

--- Build a SelectionMenuNode from this definition.
---@param parent MenuNode?
---@param game_ctx GameContext
---@param menu_ctx MenuContext
---@param _menu_state MenuState
---@return MenuNode
function SelectionMenuDefinition:to_cursor(parent, game_ctx, menu_ctx, _menu_state)
    local cursor = {
        type = "selection",
        parent = parent,
        i = 1,
        options = self.get_options(game_ctx, menu_ctx),
        has_focus = false,
    }
    return setmetatable(cursor, { __index = function(_, k)
        if SelectionMenuNode[k] then
            return SelectionMenuNode[k]
        end
        return self[k]
    end })
end

--- Create a horizontal selection definition builder.
---@param id string
---@return SelectionMenuDefinition
function selection_cursor.row(id)
    return setmetatable({
        id = id,
        direction = "horizontal",
    }, { __index = SelectionMenuDefinition })
end

--- Set the display label for this selection.
---@param label string
---@return SelectionMenuDefinition
function SelectionMenuDefinition:with_label(label)
    self.label = label
    return self
end

--- Set the serialization key for the selected value.
---@param key string
---@return SelectionMenuDefinition
function SelectionMenuDefinition:with_key(key)
    self.key = key
    return self
end

--- Set a dynamic options provider function.
---@param options fun(game_ctx: GameContext, menu_ctx: MenuContext): SelectionMenuOption[]
---@return SelectionMenuDefinition
function SelectionMenuDefinition:with_options(options)
    self.get_options = options
    return self
end

--- Configure wrapping behaviour.
---@param wrap boolean
---@return SelectionMenuDefinition
function SelectionMenuDefinition:with_wrap(wrap)
    self.wrap = wrap
    return self
end

local function get_yes_no_options(_game_ctx, _menu_ctx)
    return {
        { text = "YES", value = true },
        { text = "NO",  value = false },
    }
end

--- Pre-fill with YES/NO options and enable wrap.
---@return SelectionMenuDefinition
function SelectionMenuDefinition:with_yes_no_options()
    self.get_options = get_yes_no_options
    self.wrap = true
    return self
end

--- Pre-fill with static scalar options, converting each to text via tostring.
---@param options any[]
---@return SelectionMenuDefinition
function SelectionMenuDefinition:with_static_options(options)
    self.get_options = function(_game_ctx, _menu_ctx)
        return lists.map(function(o)
            return { text = tostring(o), value = o }
        end)(options)
    end
    return self
end

--- Pre-fill with a fixed list of SelectionMenuOption values.
---@param options SelectionMenuOption[]
---@return SelectionMenuDefinition
function SelectionMenuDefinition:with_precomputed_options(options)
    self.get_options = function(_game_ctx, _menu_ctx)
        return options
    end
    return self
end

return selection_cursor
