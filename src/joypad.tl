
global record Joypad
    dx: integer
    dxp: integer
    dy: integer
    dyp: integer
    a: boolean
    ap: boolean
    b: boolean
    bp: boolean
    lp: boolean
end

global function get_joypad(): Joypad
    local joy: Joypad = {
        -- currently locked to -1,0,1 on joysticks
        dx = (btn(1) and 1 or 0) - (btn(0) and 1 or 0),
        dxp = (btnp(1) and 1 or 0) - (btnp(0) and 1 or 0),
        dy = (btn(3) and 1 or 0) - (btn(2) and 1 or 0),
        dyp = (btnp(3) and 1 or 0) - (btnp(2) and 1 or 0),
        a = btn(4),
        ap = btnp(4),
        b = btn(5),
        bp = btnp(5),
        lp = btnp(14) -- debug button.  Set to next turn
    }

    return joy
end