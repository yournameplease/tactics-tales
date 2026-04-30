---@brief
--- Implements a menu cursor for buttons, used for event handlers
--- and menu advances.

local menu_cursor = require("src.tactics.menu.menu_cursor")
local menu_signal = menu_cursor.menu_signal

---@class MenuTileHighlight
---@field reachable boolean
---@field valid_selection boolean
---@field can_attack boolean

---@class ButtonCursor : MenuLeaf
---@field type "button"
---@field text string Button label.
---@field value any Value passed to handlers on activation.
---@field description? string Optional human-readable description.
---@field next_state? string Step to navigate to on select.
---@field final_step? boolean When true, finish the menu on select.
---@field go_back? boolean When true, go back on select.
---@field go_back_to? string When set, go back to this named step on select.
---@field handlers table<string, string>? Map from MenuCommand to MenuHandlerId.
local ButtonCursor = {}
ButtonCursor.__index = ButtonCursor

---@class ButtonDefinition : MenuLeafDefinition
---@field type "button"
---@field text string Button label.
---@field value any Value passed to handlers on activation.
---@field description? string Optional human-readable description.
---@field next_state? string Step to navigate to on select.
---@field final_step? boolean When true, finish the menu on select.
---@field go_back? boolean When true, go back on select.
---@field go_back_to? string When set, go back to this named step on select.
---@field handlers table<string, string>? Map from MenuCommand to MenuHandlerId.
local ButtonDefinition = {}
ButtonDefinition.__index = ButtonDefinition

local button = {
    ButtonCursor = ButtonCursor,
    ButtonDefinition = ButtonDefinition,
}

--- Initialize a ButtonDefinition from a property table.
---@param props ButtonDefinition
---@return ButtonDefinition
function button.definition(props)
    props.type = "button"
    return setmetatable(props, { __index = ButtonDefinition })
end

--- Handle joypad input, dispatching the first command to handle_command.
---@param _joy Joypad
---@param commands string[] Active MenuCommand values for this frame.
---@param menu_ctx MenuContext
---@param game_ctx GameContext
---@return MenuSignal
function ButtonCursor:update_joy(_joy, commands, menu_ctx, game_ctx)
    for _, command in ipairs(commands) do
        return self:handle_command(command, menu_ctx, game_ctx)
    end
    return menu_signal.ignored()
end

--- Handle mouse input; buttons do not respond to mouse events directly.
---@param _mouse Mouse
---@param _selection MenuMouseSelection
---@param _menu_ctx MenuContext
---@param _game_ctx GameContext
---@return MenuSignal
function ButtonCursor:update_mouse(_mouse, _selection, _menu_ctx, _game_ctx)
    return menu_signal.ignored()
end

--- Remove focus from this button.
function ButtonCursor:lose_focus()
    self.has_focus = false
end

--- Restore focus to this button.
function ButtonCursor:refresh_focus()
    self.has_focus = true
end

--- Claim focus for this button and propagate to parent.
---@param _selection MenuMouseSelection?
---@param _child MenuNode
function ButtonCursor:claim_focus(_selection, _child)
    self.has_focus = true
    if self.parent then
        self.parent:claim_focus(nil, self)
    end
end

--- Dispatch a menu command, returning the appropriate navigation signal.
---@param command string MenuCommand value.
---@param _menu_ctx MenuContext
---@param _game_ctx GameContext
---@return MenuSignal
function ButtonCursor:handle_command(command, _menu_ctx, _game_ctx)
    local handler = self.handlers and self.handlers[command]

    if handler then
        local signal = menu_signal.call_handler(handler, self.value)
        if command == "select" then
            if self.final_step then
                signal.then_finish = true
            elseif self.next_state then
                signal.then_navigate_to = self.next_state
            elseif self.go_back_to then
                signal.then_back_to = self.go_back_to
            elseif self.go_back then
                signal.then_back = true
            end
        end
        return signal
    end

    if command == "select" then
        if self.final_step then
            return menu_signal.finish()
        elseif self.next_state ~= nil then
            return menu_signal.navigate(self.next_state)
        elseif self.go_back_to then
            return menu_signal.back(self.go_back_to)
        elseif self.go_back then
            return menu_signal.back()
        end
    end

    return menu_signal.ignored()
end

--- Return the focused leaves; for a leaf node, that is itself.
---@param _menu_ctx MenuContext
---@param _game_ctx GameContext
---@return MenuNode[]
function ButtonCursor:get_focused_leaves(_menu_ctx, _game_ctx)
    return { self }
end

--- Serialize button state; buttons carry no persistent structural state.
---@return SerializedMenu
function ButtonCursor:serialize()
    return {
        state = nil,
        data = {},
    }
end

--- Deserialize previously saved state (no-op for buttons).
---@param _state SerializedMenuState?
---@param _data table<string, any>
function ButtonCursor:deserialize(_state, _data)
end

--- Recompute derived state (no-op for buttons).
---@param _game_ctx GameContext
---@param _menu_ctx MenuContext
function ButtonCursor:recompute(_game_ctx, _menu_ctx)
end

--- Build a ButtonCursor from this definition.
---@param parent MenuNode?
---@param _game_ctx GameContext
---@param _menu_ctx MenuContext
---@param _menu_state MenuState
---@return MenuNode
function ButtonDefinition:to_cursor(parent, _game_ctx, _menu_ctx, _menu_state)
    local cursor = {
        type = "button",
        parent = parent,
        has_focus = false,
    }
    setmetatable(cursor, { __index = function(_, k)
        if ButtonCursor[k] then
            return ButtonCursor[k]
        end
        return self[k]
    end })
    if cursor.handlers == nil then cursor.handlers = {} end
    return cursor
end

--- Create a new ButtonDefinition builder with the given ID.
---@param id string
---@return ButtonDefinition
function button.builder(id)
    return setmetatable({ id = id }, { __index = ButtonDefinition })
end

--- Set the next step to navigate to on select.
---@param next_state string
---@return ButtonDefinition
function ButtonDefinition:advance_to(next_state)
    self.next_state = next_state
    return self
end

--- Configure the button to go back on select.
---@return ButtonDefinition
function ButtonDefinition:then_go_back()
    self.go_back = true
    return self
end

--- Configure the button to go back to a named step on select.
---@param step string Target step ID to return to.
---@return ButtonDefinition
function ButtonDefinition:then_go_back_to(step)
    self.go_back_to = step
    return self
end

--- Configure the button to finish the menu on select.
---@return ButtonDefinition
function ButtonDefinition:as_final_step()
    self.final_step = true
    return self
end

--- Register a handler ID for a specific command.
---@param command string MenuCommand value.
---@param handler string MenuHandlerId to invoke when the command fires.
---@return ButtonDefinition
function ButtonDefinition:handle_action(command, handler)
    if self.handlers == nil then
        self.handlers = {}
    end
    self.handlers[command] = handler
    return self
end

--- Set the button label.
---@param text string
---@return ButtonDefinition
function ButtonDefinition:with_text(text)
    self.text = text
    return self
end

--- Set the button description.
---@param description string
---@return ButtonDefinition
function ButtonDefinition:with_description(description)
    self.description = description
    return self
end

--- Set the value passed to handlers on activation.
---@param value any
---@return ButtonDefinition
function ButtonDefinition:with_value(value)
    self.value = value
    return self
end

return button
