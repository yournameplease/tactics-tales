local luassert = require("luassert")
local input_service = require("src.tactics.joypad")

-- Helpers to override Picotron globals per-test.
local original_btn      = pt.btn
local original_btnp     = pt.btnp
local original_get_mouse = pt.get_mouse

after_each(function()
    pt.btn       = original_btn
    pt.btnp      = original_btnp
    pt.get_mouse = original_get_mouse
end)

--- Build a btn/btnp stub that returns true only for the listed button indices.
local function btn_returns(...)
    local pressed = {}
    for _, b in ipairs({...}) do pressed[b] = true end
    return function(b) return pressed[b] or false end
end

--- Build a get_mouse stub returning the given values (defaults to all-zero/idle).
local function mouse_returns(mx, my, buttons, wx, wy)
    return function() return mx or 0, my or 0, buttons or 0, wx or 0, wy or 0 end
end

describe("tactics.joypad", function()
    describe("joypad pressed/released logic", function()
        it("should report pressed=true and held=true on the first frame a button is held", function()
            pt.btn  = btn_returns(4)       -- A button held
            pt.btnp = btn_returns(4)       -- A button pressed this frame
            -- Ensure no mouse activity so current_input stays "joypad"
            pt.get_mouse = mouse_returns()

            local svc = input_service.new()
            svc.current_input = "joypad"
            local inp = svc:get_user_input()

            luassert.is_true(inp.actions["BUTTON_A"].held)
            luassert.is_true(inp.actions["BUTTON_A"].pressed)
            luassert.is_false(inp.actions["BUTTON_A"].released)
        end)

        it("should report pressed=false and held=true on the second frame a button is held", function()
            pt.btn  = btn_returns(4)
            pt.btnp = btn_returns(4)
            pt.get_mouse = mouse_returns()

            local svc = input_service.new()
            svc.current_input = "joypad"
            svc:get_user_input()           -- frame 1: pressed

            pt.btnp = btn_returns()        -- no longer newly pressed
            local inp = svc:get_user_input() -- frame 2: still held

            luassert.is_true(inp.actions["BUTTON_A"].held)
            luassert.is_false(inp.actions["BUTTON_A"].pressed)
            luassert.is_false(inp.actions["BUTTON_A"].released)
        end)

        it("should report released=true and held=false on the frame a button is released", function()
            pt.btn  = btn_returns(4)
            pt.btnp = btn_returns(4)
            pt.get_mouse = mouse_returns()

            local svc = input_service.new()
            svc.current_input = "joypad"
            svc:get_user_input()           -- frame 1: pressed

            pt.btnp = btn_returns()
            svc:get_user_input()           -- frame 2: held

            pt.btn  = btn_returns()        -- released
            pt.btnp = btn_returns()
            local inp = svc:get_user_input() -- frame 3: released

            luassert.is_false(inp.actions["BUTTON_A"].held)
            luassert.is_false(inp.actions["BUTTON_A"].pressed)
            luassert.is_true(inp.actions["BUTTON_A"].released)
        end)

        it("should map joypad shoulder buttons to SHOULDER_L and SHOULDER_R actions", function()
            pt.btn  = btn_returns(14, 15)  -- L and R shoulders held
            pt.btnp = btn_returns(14, 15)
            pt.get_mouse = mouse_returns()

            local svc = input_service.new()
            svc.current_input = "joypad"
            local inp = svc:get_user_input()

            luassert.is_true(inp.actions["SHOULDER_L"].held)
            luassert.is_true(inp.actions["SHOULDER_R"].held)
        end)

        it("should report method_changed=true on the first call", function()
            pt.btn  = btn_returns(4)
            pt.btnp = btn_returns(4)
            pt.get_mouse = mouse_returns()

            local svc = input_service.new()
            svc.current_input = "joypad"
            local inp = svc:get_user_input()

            -- previous_input was nil, so it changed
            luassert.is_true(inp.method_changed)
        end)
    end)

    describe("mouse pressed/released logic", function()
        it("should report held=true and pressed=true on the first frame left button is down", function()
            -- mouse_b = 1 → ml = true (bit 0)
            pt.get_mouse = mouse_returns(0, 0, 1)
            pt.btn  = btn_returns()
            pt.btnp = btn_returns()

            local svc = input_service.new()   -- starts in "mouse" mode
            local inp = svc:get_user_input()

            luassert.is_true(inp.actions["BUTTON_A"].held)
            luassert.is_true(inp.actions["BUTTON_A"].pressed)
            luassert.is_false(inp.actions["BUTTON_A"].released)
        end)

        it("should report pressed=false and held=true on the second consecutive frame", function()
            pt.get_mouse = mouse_returns(0, 0, 1)
            pt.btn  = btn_returns()
            pt.btnp = btn_returns()

            local svc = input_service.new()
            svc:get_user_input()             -- frame 1

            local inp = svc:get_user_input() -- frame 2: still held

            luassert.is_true(inp.actions["BUTTON_A"].held)
            luassert.is_false(inp.actions["BUTTON_A"].pressed)
            luassert.is_false(inp.actions["BUTTON_A"].released)
        end)

        it("should report released=true and held=false on the frame the button is released", function()
            pt.get_mouse = mouse_returns(0, 0, 1)
            pt.btn  = btn_returns()
            pt.btnp = btn_returns()

            local svc = input_service.new()
            svc:get_user_input()             -- frame 1: pressed
            svc:get_user_input()             -- frame 2: held

            pt.get_mouse = mouse_returns(0, 0, 0)
            local inp = svc:get_user_input() -- frame 3: released

            luassert.is_false(inp.actions["BUTTON_A"].held)
            luassert.is_false(inp.actions["BUTTON_A"].pressed)
            luassert.is_true(inp.actions["BUTTON_A"].released)
        end)

        it("should map right mouse button to BUTTON_B", function()
            -- mouse_b = 2 → mr = true (bit 1)
            pt.get_mouse = mouse_returns(0, 0, 2)
            pt.btn  = btn_returns()
            pt.btnp = btn_returns()

            local svc = input_service.new()
            local inp = svc:get_user_input()

            luassert.is_true(inp.actions["BUTTON_B"].held)
            luassert.is_false(inp.actions["SHOULDER_L"].held)
            luassert.is_false(inp.actions["SHOULDER_R"].held)
        end)

        it("should derive mlp correctly on the first frame when mouse_prev is nil", function()
            pt.get_mouse = mouse_returns(0, 0, 1)
            pt.btn  = btn_returns()
            pt.btnp = btn_returns()

            local svc = input_service.new()
            local inp = svc:get_user_input()

            -- On first frame, mlp mirrors ml
            luassert.is_true(inp.mouse.ml)
            luassert.is_true(inp.mouse.mlp)
        end)

        it("should derive mlp=false on the second frame when button was already held", function()
            pt.get_mouse = mouse_returns(0, 0, 1)
            pt.btn  = btn_returns()
            pt.btnp = btn_returns()

            local svc = input_service.new()
            svc:get_user_input()             -- frame 1

            local inp = svc:get_user_input() -- frame 2: still held, mlp should be false

            luassert.is_true(inp.mouse.ml)
            luassert.is_false(inp.mouse.mlp)
        end)
    end)

    describe("input method switching", function()
        it("should switch active_method to joypad when a joy button is pressed", function()
            pt.get_mouse = mouse_returns()
            pt.btn  = btn_returns(4)
            pt.btnp = btn_returns(4)

            local svc = input_service.new()  -- starts "mouse"
            local inp = svc:get_user_input()

            luassert.are_equal("joypad", inp.active_method)
        end)

        it("should stay in mouse mode when no joypad input is present", function()
            pt.get_mouse = mouse_returns(0, 0, 1)
            pt.btn  = btn_returns()
            pt.btnp = btn_returns()

            local svc = input_service.new()
            local inp = svc:get_user_input()

            luassert.are_equal("mouse", inp.active_method)
        end)
    end)
end)
