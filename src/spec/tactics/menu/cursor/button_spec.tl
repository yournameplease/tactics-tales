local type _ = require("busted")
local luassert <const> = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local button = require("src.tactics.menu.cursor.button")
local event_bus = require("src.tactics.systems.event_bus")
local menu_context = require("src.tactics.menu.menu_context")
local input_context = require("src.tactics.input.input_context")
local joypad_service = require("src.tactics.joypad")

describe("tactics.menu.cursor.button", function()
    local bus: event_bus.EventBus
    local ctx: menu_context.GameContext

    before_each(function()
        bus = event_bus.new()
        ctx = {} as menu_context.GameContext
    end)

    it("should trigger a handler when pressed via joypad", function()
        local handler_called = false
        local handler_value: any = nil

        local handlers: { string: menu_manager.MenuHandler } = {
            ["test_handler"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, value: any): menu_manager.menu_handler.MenuHandlerPostHandling
                handler_called = true
                handler_value = value
                return nil
            end
        }

        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("test_button")
                            :with_text("Test Button")
                            :with_value("test_value")
                            :handle_action("select", "test_handler")
                    ):with_action("BUTTON_A", { command = "select", description = "Select" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")

        local joypad: joypad_service.Joypad = {
            dx = 0, dxp = 0, dy = 0, dyp = 0,
            a = true, ap = true, b = false, bp = false,
            l = false, lp = false, r = false, rp = false
        }
        local actions: joypad_service.InputActions = {
            ["BUTTON_A"] = { held = true, pressed = true, released = false },
            ["BUTTON_B"] = { held = false, pressed = false, released = false },
            ["SHOULDER_L"] = { held = false, pressed = false, released = false },
            ["SHOULDER_R"] = { held = false, pressed = false, released = false },
        }
        
        local input = input_context.joypad(joypad, actions)
        manager:update(input)

        luassert.is_true(handler_called)
        luassert.are_equal("test_value", handler_value)
    end)

    it("should navigate to next state when configured", function()
        local handlers: { string: menu_manager.MenuHandler } = {}
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1")
                            :advance_to("STEP_2")
                    ):with_action("BUTTON_A", { command = "select" }),
                    ["STEP_2"] = menu_manager.definition.step.of_node(
                        button.builder("btn2")
                            :with_text("Step 2")
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")

        local joypad: joypad_service.Joypad = {
            dx = 0, dxp = 0, dy = 0, dyp = 0,
            a = false, ap = true, b = false, bp = false,
            l = false, lp = false, r = false, rp = false
        }
        local actions: joypad_service.InputActions = {
            ["BUTTON_A"] = { held = false, pressed = true, released = false },
            ["BUTTON_B"] = { held = false, pressed = false, released = false },
            ["SHOULDER_L"] = { held = false, pressed = false, released = false },
            ["SHOULDER_R"] = { held = false, pressed = false, released = false },
        }
        manager:update(input_context.joypad(joypad, actions))

        luassert.are_equal("STEP_2", manager.menu_state.step)
    end)
    
    it("should go back when configured", function()
        local handlers: { string: menu_manager.MenuHandler } = {}
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1"):advance_to("STEP_2")
                    ):with_action("BUTTON_A", { command = "select" }),
                    ["STEP_2"] = menu_manager.definition.step.of_node(
                        button.builder("btn2"):then_go_back()
                    ):with_previous_step("STEP_1")
                     :with_action("BUTTON_A", { command = "select" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")

        local joypad: joypad_service.Joypad = {
            dx = 0, dxp = 0, dy = 0, dyp = 0,
            a = false, ap = true, b = false, bp = false,
            l = false, lp = false, r = false, rp = false
        }
        local actions: joypad_service.InputActions = {
            ["BUTTON_A"] = { held = false, pressed = true, released = false },
            ["BUTTON_B"] = { held = false, pressed = false, released = false },
            ["SHOULDER_L"] = { held = false, pressed = false, released = false },
            ["SHOULDER_R"] = { held = false, pressed = false, released = false },
        }

        -- advance to STEP_2
        manager:update(input_context.joypad(joypad, actions))
        luassert.are_equal("STEP_2", manager.menu_state.step)

        -- go back to STEP_1
        manager:update(input_context.joypad(joypad, actions))
        luassert.are_equal("STEP_1", manager.menu_state.step)
    end)

    it("should finish menu when as_final_step is set", function()
        local handlers: { string: menu_manager.MenuHandler } = {}
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1"):as_final_step()
                    ):with_action("BUTTON_A", { command = "select" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")

        local joypad: joypad_service.Joypad = {
            dx = 0, dxp = 0, dy = 0, dyp = 0,
            a = false, ap = true, b = false, bp = false,
            l = false, lp = false, r = false, rp = false
        }
        local actions: joypad_service.InputActions = {
            ["BUTTON_A"] = { held = false, pressed = true, released = false },
            ["BUTTON_B"] = { held = false, pressed = false, released = false },
            ["SHOULDER_L"] = { held = false, pressed = false, released = false },
            ["SHOULDER_R"] = { held = false, pressed = false, released = false },
        }

        manager:update(input_context.joypad(joypad, actions))
        luassert.is_nil(manager.menu_state.menu_id)
    end)
end)
