local input_context = require("src.tactics.input.input_context")

---@class InputHelper
local InputHelper = {}

---@param props table<string, any>
---@return InputContext
function InputHelper.joypad(props)
    local joy = {
        dx  = props.dx  or 0,
        dxp = props.dxp or 0,
        dy  = props.dy  or 0,
        dyp = props.dyp or 0,
        a   = props.a   or false,
        ap  = props.ap  or false,
        b   = props.b   or false,
        bp  = props.bp  or false,
        l   = props.l   or false,
        lp  = props.lp  or false,
        r   = props.r   or false,
        rp  = props.rp  or false,
    }

    ---@type InputActions
    local actions = {
        ["BUTTON_A"]  = { held = joy.a, pressed = joy.ap, released = false },
        ["BUTTON_B"]  = { held = joy.b, pressed = joy.bp, released = false },
        ["SHOULDER_L"] = { held = joy.l, pressed = joy.lp, released = false },
        ["SHOULDER_R"] = { held = joy.r, pressed = joy.rp, released = false },
    }

    return input_context.joypad(joy, actions)
end

return InputHelper
