local type _ = require("busted")
local luassert <const> = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local selection = require("src.tactics.menu.cursor.selection")
local event_bus = require("src.tactics.systems.event_bus")
local menu_context = require("src.tactics.menu.menu_context")
local input_context = require("src.tactics.input.input_context")
local joypad_service = require("src.tactics.joypad")

describe("tactics.menu.cursor.selection", function()
    local bus: event_bus.EventBus
    local ctx: menu_context.GameContext

    before_each(function()
        bus = event_bus.new()
        ctx = {} as menu_context.GameContext
    end)

    it("should cycle options using joypad horizontal input", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        selection.row("test_sel")
                            :with_static_options({"A", "B", "C"})
                            :with_wrap(true)
                    ):with_action("BUTTON_A", { command = "select" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node as selection.SelectionMenuNode
        luassert.are_equal("A", node:get_selected_value())

        local joypad: joypad_service.Joypad = {
            dx = 0, dxp = 0, dy = 0, dyp = 0,
            a = false, ap = false, b = false, bp = false,
            l = false, lp = false, r = false, rp = false
        }
        local actions: joypad_service.InputActions = {
            ["BUTTON_A"] = { held = false, pressed = false, released = false },
            ["BUTTON_B"] = { held = false, pressed = false, released = false },
            ["SHOULDER_L"] = { held = false, pressed = false, released = false },
            ["SHOULDER_R"] = { held = false, pressed = false, released = false },
        }

        -- move right
        joypad.dxp = 1
        manager:update(input_context.joypad(joypad, actions))
        luassert.are_equal("B", node:get_selected_value())

        -- move right again
        manager:update(input_context.joypad(joypad, actions))
        luassert.are_equal("C", node:get_selected_value())

        -- wrap around
        manager:update(input_context.joypad(joypad, actions))
        luassert.are_equal("A", node:get_selected_value())

        -- move left
        joypad.dxp = -1
        manager:update(input_context.joypad(joypad, actions))
        luassert.are_equal("C", node:get_selected_value())
    end)

    it("should deserialize initial data correctly", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        selection.row("test_sel")
                            :with_key("my_key")
                            :with_static_options({"A", "B", "C"})
                    ):with_initial_data(function(_: menu_context.GameContext, _: menu_context.MenuContext): {string: any}
                        return { ["my_key"] = "B" }
                    end)
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node as selection.SelectionMenuNode
        luassert.are_equal("B", node:get_selected_value())
    end)

    it("should serialize selected value", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        selection.row("test_sel")
                            :with_key("my_key")
                            :with_static_options({"A", "B", "C"})
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local joypad: joypad_service.Joypad = {
            dx = 0, dxp = 1, dy = 0, dyp = 0,
            a = false, ap = false, b = false, bp = false,
            l = false, lp = false, r = false, rp = false
        }
        local actions: joypad_service.InputActions = {
            ["BUTTON_A"] = { held = false, pressed = false, released = false },
            ["BUTTON_B"] = { held = false, pressed = false, released = false },
            ["SHOULDER_L"] = { held = false, pressed = false, released = false },
            ["SHOULDER_R"] = { held = false, pressed = false, released = false },
        }
        manager:update(input_context.joypad(joypad, actions))
        
        local ser = manager:serialize()
        luassert.are_equal("B", ser.node.data["my_key"])
    end)
end)
