local luassert = require("luassert")
local input_context = require("src.tactics.input.input_context")

--- Minimal Joypad stub.
---@return Joypad
local function make_joy()
    return { dx = 0, dxp = 0, dy = 0, dyp = 0, a = false, ap = false, b = false, bp = false, l = false, lp = false, r = false, rp = false }
end

--- Minimal Mouse stub.
---@return Mouse
local function make_mouse()
    return { mx = 0, my = 0, ml = false, mlp = false, mr = false, mrp = false, mm = false, mmp = false, wheel_x = 0, wheel_y = 0 }
end

--- Minimal InputActions stub (all released, not held).
---@return InputActions
local function make_actions()
    return {
        ["BUTTON_A"]   = { held = false, pressed = false, released = false },
        ["BUTTON_B"]   = { held = false, pressed = false, released = false },
        ["SHOULDER_L"] = { held = false, pressed = false, released = false },
        ["SHOULDER_R"] = { held = false, pressed = false, released = false },
    }
end

--- Minimal MenuMouseSelection stub (leaf type).
local function make_hovered()
    return { type = "leaf" }
end

describe("tactics.input.input_context", function()
    describe("joypad constructor", function()
        it("should set type to 'joypad'", function()
            local ctx = input_context.joypad(make_joy(), make_actions())
            luassert.are_equal("joypad", ctx.type)
        end)

        it("should store the provided joypad state", function()
            local joy = make_joy()
            joy.a = true
            local ctx = input_context.joypad(joy, make_actions())
            ---@cast ctx JoypadContext
            luassert.is_true(ctx.joypad.a)
        end)

        it("should store the provided actions", function()
            local actions = make_actions()
            actions["BUTTON_A"].held = true
            local ctx = input_context.joypad(make_joy(), actions)
            luassert.is_true(ctx.actions["BUTTON_A"].held)
        end)
    end)

    describe("mouse constructor", function()
        it("should set type to 'mouse'", function()
            local ctx = input_context.mouse(make_mouse(), make_hovered(), make_actions())
            luassert.are_equal("mouse", ctx.type)
        end)

        it("should store the provided mouse state", function()
            local mouse = make_mouse()
            mouse.ml = true
            local ctx = input_context.mouse(mouse, make_hovered(), make_actions())
            ---@cast ctx MouseContext
            luassert.is_true(ctx.mouse.ml)
        end)

        it("should store the provided hovered selection", function()
            local hovered = make_hovered()
            local ctx = input_context.mouse(make_mouse(), hovered, make_actions())
            ---@cast ctx MouseContext
            luassert.are_equal(hovered, ctx.hovered)
        end)

        it("should store the provided actions", function()
            local actions = make_actions()
            actions["BUTTON_B"].pressed = true
            local ctx = input_context.mouse(make_mouse(), make_hovered(), actions)
            luassert.is_true(ctx.actions["BUTTON_B"].pressed)
        end)
    end)

    describe("handle_update", function()
        it("should call update_joy and return its result for a joypad context", function()
            local joy = make_joy()
            joy.dy = 1
            local ctx = input_context.joypad(joy, make_actions())

            local result = input_context.handle_update(
                ctx,
                function(j) return j.dy end,
                function(_m, _h) return -1 end
            )

            luassert.are_equal(1, result)
        end)

        it("should call update_mouse and return its result for a mouse context", function()
            local mouse = make_mouse()
            mouse.mx = 42
            local hovered = make_hovered()
            local ctx = input_context.mouse(mouse, hovered, make_actions())

            local result = input_context.handle_update(
                ctx,
                function(_j) return -1 end,
                function(m, _h) return m.mx end
            )

            luassert.are_equal(42, result)
        end)

        it("should pass the hovered selection to the mouse handler", function()
            local hovered = make_hovered()
            local ctx = input_context.mouse(make_mouse(), hovered, make_actions())

            local captured_hovered
            input_context.handle_update(
                ctx,
                function(_) return nil end,
                function(_, h)
                    captured_hovered = h; return nil
                end
            )

            luassert.are_equal(hovered, captured_hovered)
        end)

        it("should not call update_mouse for a joypad context", function()
            local ctx = input_context.joypad(make_joy(), make_actions())
            local mouse_called = false

            input_context.handle_update(
                ctx,
                function(_) return nil end,
                function(_, _h)
                    mouse_called = true; return nil
                end
            )

            luassert.is_false(mouse_called)
        end)

        it("should not call update_joy for a mouse context", function()
            local ctx = input_context.mouse(make_mouse(), make_hovered(), make_actions())
            local joy_called = false

            input_context.handle_update(
                ctx,
                function(_)
                    joy_called = true; return nil
                end,
                function(_, _h) return nil end
            )

            luassert.is_false(joy_called)
        end)

        it("should error for an unknown context type", function()
            ---@diagnostic disable-next-line: assign-type-mismatch
            local bad_ctx = { type = "gamepad", actions = make_actions() }

            luassert.has_error(function()
                ---@cast bad_ctx InputContext
                input_context.handle_update(bad_ctx, function(_) return nil end, function(_, _h) return nil end)
            end)
        end)
    end)
end)
