local record Mouse
    mx: number
    my: number

    ml: boolean
    mlp: boolean
    mr: boolean
    mrp: boolean
    mm: boolean
    mmp: boolean
end

local record Joypad
    dx: integer
    dxp: integer
    dy: integer
    dyp: integer
    a: boolean
    ap: boolean
    b: boolean
    bp: boolean
    l: boolean
    lp: boolean
    r: boolean
    rp: boolean
end

local enum InputMethod
    "mouse"
    "joypad"
end

local record UserInput
    active_method: InputMethod

    joypad: Joypad
    mouse: Mouse
end

local interface InputService
    get_user_input: function(self): UserInput
end

local input_service = {
    InputMethod = InputMethod,
    Joypad = Joypad,
    Mouse = Mouse,
    UserInput = UserInput,
    InputService = InputService,
}

local record InputServiceImpl
    is InputService

    current_input: InputMethod
    mouse_prev: Mouse
end

function InputServiceImpl:get_mouse(): Mouse
    local mouse_x, mouse_y, mouse_b, _wheel_x, _wheel_y = pt.get_mouse()
                
    local mouse: Mouse = {
        mx = mouse_x,
        my = mouse_y,
        ml = mouse_b & 0x1 == 0x1,
        mr = mouse_b & 0x2 == 0x2,
        mm = mouse_b & 0x4 == 0x4,
    }

    if self.mouse_prev ~= nil then
        mouse.mlp = mouse.ml and not self.mouse_prev.ml
        mouse.mrp = mouse.mr and not self.mouse_prev.mr
        mouse.mmp = mouse.mm and not self.mouse_prev.mm
    else
        mouse.mlp = mouse.ml
        mouse.mrp = mouse.mr
        mouse.mmp = mouse.mm
    end

    return mouse
end

function InputServiceImpl:get_joypad(): Joypad
    local joy: Joypad = {
        -- currently locked to -1,0,1 on joysticks
        dx = (pt.btn(1) and 1 or 0) - (pt.btn(0) and 1 or 0),
        dxp = (pt.btnp(1) and 1 or 0) - (pt.btnp(0) and 1 or 0),
        dy = (pt.btn(3) and 1 or 0) - (pt.btn(2) and 1 or 0),
        dyp = (pt.btnp(3) and 1 or 0) - (pt.btnp(2) and 1 or 0),
        a = pt.btn(4),
        ap = pt.btnp(4),
        b = pt.btn(5),
        bp = pt.btnp(5),
        l = pt.btn(14),
        lp = pt.btnp(14),
        r = pt.btn(15),
        rp = pt.btnp(15),
    }

    return joy
end

function InputServiceImpl:get_user_input(): UserInput
    local joy = self:get_joypad()
    local mouse = self:get_mouse()

    local any_joy =
        joy.dx ~= 0
        or joy.dy ~= 0
        or joy.a
        or joy.b
        or joy.l
        or joy.r

    
    local any_mouse =
        (self.mouse_prev and pt.absf(mouse.mx - self.mouse_prev.mx) > 1)
        or (self.mouse_prev and pt.absf(mouse.my - self.mouse_prev.my) > 1)
        or mouse.ml
        or mouse.mr
        or mouse.mm

    if any_joy then self.current_input = "joypad" end
    if any_mouse then self.current_input = "mouse" end

    return {
        joypad = joy,
        mouse = mouse,
        active_method = self.current_input,
    }
end

function input_service.new(): InputService
    local self: InputServiceImpl = setmetatable({
        current_input = "joypad",
        mouse_prev = nil,
    },{
        __index = InputServiceImpl
    })
    return self
end

return input_service
