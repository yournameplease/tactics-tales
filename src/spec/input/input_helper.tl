local input_context = require("src.tactics.input.input_context")
local joypad_service = require("src.tactics.joypad")

local record InputHelper
end

function InputHelper.joypad(props: {string: any}): input_context.InputContext
    local joy: joypad_service.Joypad = {
        dx = (props.dx or 0) as integer,
        dxp = (props.dxp or 0) as integer,
        dy = (props.dy or 0) as integer,
        dyp = (props.dyp or 0) as integer,
        a = (props.a or false) as boolean,
        ap = (props.ap or false) as boolean,
        b = (props.b or false) as boolean,
        bp = (props.bp or false) as boolean,
        l = (props.l or false) as boolean,
        lp = (props.lp or false) as boolean,
        r = (props.r or false) as boolean,
        rp = (props.rp or false) as boolean,
    }

    local actions: joypad_service.InputActions = {
        ["BUTTON_A"] = { held = joy.a, pressed = joy.ap, released = false },
        ["BUTTON_B"] = { held = joy.b, pressed = joy.bp, released = false },
        ["SHOULDER_L"] = { held = joy.l, pressed = joy.lp, released = false },
        ["SHOULDER_R"] = { held = joy.r, pressed = joy.rp, released = false },
    }

    return input_context.joypad(joy, actions)
end

return InputHelper
