---@brief
--- Provides an input service for handling joypad and mouse input and
--- mapping them to game actions.

---@alias InputAction "BUTTON_A"|"BUTTON_B"|"SHOULDER_L"|"SHOULDER_R"

---@alias InputMethod "mouse"|"joypad"

---@class InputActionState
---@field held boolean Whether the action button is currently held down.
---@field pressed boolean True on the first frame the action transitions from unpressed to held.
---@field released boolean True on the first frame the action transitions from held to unpressed.

---@alias InputActions table<InputAction, InputActionState>

---@class Mouse
---@field mx number
---@field my number
---@field ml boolean Left mouse button held.
---@field mlp boolean Left mouse button pressed this frame.
---@field mr boolean Right mouse button held.
---@field mrp boolean Right mouse button pressed this frame.
---@field mm boolean Middle mouse button held.
---@field mmp boolean Middle mouse button pressed this frame.
---@field wheel_x number
---@field wheel_y number

---@class Joypad
---@field dx integer Horizontal axis: -1 (left), 0 (neutral), 1 (right).
---@field dxp integer Horizontal axis newly pressed this frame.
---@field dy integer Vertical axis: -1 (up), 0 (neutral), 1 (down).
---@field dyp integer Vertical axis newly pressed this frame.
---@field a boolean A button held.
---@field ap boolean A button pressed this frame.
---@field b boolean B button held.
---@field bp boolean B button pressed this frame.
---@field l boolean Left shoulder button held.
---@field lp boolean Left shoulder button pressed this frame.
---@field r boolean Right shoulder button held.
---@field rp boolean Right shoulder button pressed this frame.

---@class UserInput
---@field active_method InputMethod The input method that was active this frame.
---@field method_changed boolean True if the active input method changed since the last frame.
---@field actions InputActions Logical action states derived from the active input method.
---@field joypad Joypad Raw joypad state for this frame.
---@field mouse Mouse Raw mouse state for this frame.

---@class InputService Abstract interface implemented by InputServiceImpl.
---@field current_input InputMethod The currently active input method.
---@field get_user_input fun(self: InputService): UserInput Return the current frame's unified user input state.

---@class InputServiceImpl : InputService
---@field actions InputActions Persistent action state table updated each frame.
---@field previous_input InputMethod|nil The active input method from the previous frame.
---@field mouse_prev Mouse|nil The mouse state from the previous frame, or nil on the first frame.
local InputServiceImpl = {}
InputServiceImpl.__index = InputServiceImpl

--- Read raw mouse state from the Picotron API and compute pressed-this-frame flags.
---@return Mouse
function InputServiceImpl:get_mouse()
    local mouse_x, mouse_y, mouse_b, wheel_x, wheel_y = pt.get_mouse()

    local ml = mouse_b & 0x1 == 0x1
    local mr = mouse_b & 0x2 == 0x2
    local mm = mouse_b & 0x4 == 0x4

    ---@type Mouse
    local mouse = {
        mx      = mouse_x,
        my      = mouse_y,
        ml      = ml,
        mlp     = false,
        mr      = mr,
        mrp     = false,
        mm      = mm,
        mmp     = false,
        wheel_x = wheel_x,
        wheel_y = wheel_y,
    }

    if self.mouse_prev ~= nil then
        mouse.mlp = ml and not self.mouse_prev.ml
        mouse.mrp = mr and not self.mouse_prev.mr
        mouse.mmp = mm and not self.mouse_prev.mm
    else
        mouse.mlp = ml
        mouse.mrp = mr
        mouse.mmp = mm
    end

    return mouse
end

--- Read raw joypad state from the Picotron API.
---@return Joypad
function InputServiceImpl:get_joypad()
    ---@type Joypad
    local joy = {
        -- currently locked to -1, 0, 1 on joysticks
        dx  = (pt.btn(1) and 1 or 0) - (pt.btn(0) and 1 or 0),
        dxp = (pt.btnp(1) and 1 or 0) - (pt.btnp(0) and 1 or 0),
        dy  = (pt.btn(3) and 1 or 0) - (pt.btn(2) and 1 or 0),
        dyp = (pt.btnp(3) and 1 or 0) - (pt.btnp(2) and 1 or 0),
        a   = pt.btn(4),
        ap  = pt.btnp(4),
        b   = pt.btn(5),
        bp  = pt.btnp(5),
        l   = pt.btn(14),
        lp  = pt.btnp(14),
        r   = pt.btn(15),
        rp  = pt.btnp(15),
    }
    return joy
end

--- Sample raw input, update action pressed/released state, and return a unified UserInput.
---@return UserInput
function InputServiceImpl:get_user_input()
    local joy   = self:get_joypad()
    local mouse = self:get_mouse()

    local any_joy =
        joy.dx ~= 0
        or joy.dy ~= 0
        or joy.a
        or joy.b
        or joy.l
        or joy.r

    local any_mouse =
        (self.mouse_prev and math.abs(mouse.mx - self.mouse_prev.mx) > 1)
        or (self.mouse_prev and math.abs(mouse.my - self.mouse_prev.my) > 1)
        or mouse.ml
        or mouse.mr
        or mouse.mm

    if any_joy   then self.current_input = "joypad" end
    if any_mouse then self.current_input = "mouse"  end

    ---@type table<InputAction, boolean>
    local new_actions
    if self.current_input == "mouse" then
        new_actions = {
            ["BUTTON_A"]  = mouse.ml,
            ["BUTTON_B"]  = mouse.mr,
            ["SHOULDER_L"] = false,
            ["SHOULDER_R"] = false,
        }
    else
        new_actions = {
            ["BUTTON_A"]  = joy.a,
            ["BUTTON_B"]  = joy.b,
            ["SHOULDER_L"] = joy.l,
            ["SHOULDER_R"] = joy.r,
        }
    end

    for k, held in pairs(new_actions) do
        self.actions[k].pressed  = held and not self.actions[k].held
        self.actions[k].released = not held and self.actions[k].held
        self.actions[k].held     = held
    end

    ---@type UserInput
    local out = {
        joypad         = joy,
        mouse          = mouse,
        active_method  = self.current_input,
        method_changed = self.current_input ~= self.previous_input,
        actions        = self.actions,
    }

    self.mouse_prev    = mouse
    self.previous_input = self.current_input

    return out
end

local input_service = {}

--- Create a new InputService starting in mouse mode.
---@return InputService
function input_service.new()
    ---@type InputActions
    local actions = {
        ["BUTTON_A"]   = { held = false, pressed = false, released = false },
        ["BUTTON_B"]   = { held = false, pressed = false, released = false },
        ["SHOULDER_L"] = { held = false, pressed = false, released = false },
        ["SHOULDER_R"] = { held = false, pressed = false, released = false },
    }
    ---@type InputServiceImpl
    local self = setmetatable({
        current_input   = "mouse",
        previous_input  = nil,
        mouse_prev      = nil,
        actions         = actions,
    }, InputServiceImpl)
    return self
end

return input_service
