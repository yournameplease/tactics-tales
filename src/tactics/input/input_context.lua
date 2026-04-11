---@brief
--- Defines a unified context for handling both joypad and mouse input,
--- abstracting the specific input method from the systems that use it.

---@class InputContext Abstract base for JoypadContext and MouseContext.
---@field type InputMethod The active input method for this context.
---@field actions InputActions Logical action states for this frame.

---@class JoypadContext : InputContext
---@field type "joypad"
---@field joypad Joypad Raw joypad state for this frame.

---@class MouseContext : InputContext
---@field type "mouse"
---@field mouse Mouse Raw mouse state for this frame.
---@field hovered MenuMouseSelection The menu element currently under the cursor.

local input_context = {}

--- Create an InputContext for a joypad frame.
---@param joypad Joypad Raw joypad state for this frame.
---@param actions InputActions Logical action states derived from joypad buttons.
---@return InputContext
function input_context.joypad(joypad, actions)
    ---@type JoypadContext
    local self = {
        type    = "joypad",
        joypad  = joypad,
        actions = actions,
    }
    return self
end

--- Create an InputContext for a mouse frame.
---@param mouse Mouse Raw mouse state for this frame.
---@param hovered MenuMouseSelection The menu element currently under the cursor.
---@param actions InputActions Logical action states derived from mouse buttons.
---@return InputContext
function input_context.mouse(mouse, hovered, actions)
    ---@type MouseContext
    local self = {
        type    = "mouse",
        mouse   = mouse,
        hovered = hovered,
        actions = actions,
    }
    return self
end

--- Dispatch to the appropriate handler based on the context's input method.
--- Calls `update_joy` for joypad contexts and `update_mouse` for mouse contexts.
---@generic Return
---@param ctx InputContext
---@param update_joy fun(joy: Joypad): Return Handler invoked when ctx is a joypad context.
---@param update_mouse fun(mouse: Mouse, hovered: MenuMouseSelection): Return Handler invoked when ctx is a mouse context.
---@return Return
function input_context.handle_update(ctx, update_joy, update_mouse)
    if ctx.type == "joypad" then
        ---@cast ctx JoypadContext
        return update_joy(ctx.joypad)
    elseif ctx.type == "mouse" then
        ---@cast ctx MouseContext
        return update_mouse(ctx.mouse, ctx.hovered)
    else
        error("unexpected input context type: " .. tostring(ctx.type))
    end
end

return input_context
