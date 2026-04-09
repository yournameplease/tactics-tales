local luassert = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local button = require("src.tactics.menu.cursor.button")
local event_bus = require("src.tactics.systems.event_bus")
local input_helper = require("src.spec.input.input_helper")

describe("tactics.menu.menu_manager", function()
    local bus
    local ctx

    before_each(function()
        bus = event_bus.new()
        ctx = {}
    end)

    it("should maintain selection history and handle multiple back steps", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1"):advance_to("STEP_2")
                    ):with_action("BUTTON_A", { command = "select" }),
                    ["STEP_2"] = menu_manager.definition.step.of_node(
                        button.builder("btn2"):advance_to("STEP_3")
                    ):with_previous_step("STEP_1")
                     :with_action("BUTTON_A", { command = "select" })
                     :with_action("BUTTON_B", { command = "back" }),
                    ["STEP_3"] = menu_manager.definition.step.of_node(
                        button.builder("btn3"):with_text("Finish")
                    ):with_previous_step("STEP_2")
                     :with_action("BUTTON_B", { command = "back" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        luassert.are_equal("STEP_1", manager.menu_state.step)
        luassert.are_equal(0, #manager.selection_history)

        -- to STEP_2
        manager:update(input_helper.joypad({ ap = true }))
        luassert.are_equal("STEP_2", manager.menu_state.step)
        luassert.are_equal(1, #manager.selection_history)
        luassert.are_equal("STEP_1", manager.selection_history[1].step)

        -- to STEP_3
        manager:update(input_helper.joypad({ ap = true }))
        luassert.are_equal("STEP_3", manager.menu_state.step)
        luassert.are_equal(2, #manager.selection_history)
        luassert.are_equal("STEP_2", manager.selection_history[2].step)

        -- back to STEP_2
        manager:update(input_helper.joypad({ bp = true }))
        luassert.are_equal("STEP_2", manager.menu_state.step)
        luassert.are_equal(1, #manager.selection_history)

        -- back to STEP_1
        manager:update(input_helper.joypad({ bp = true }))
        luassert.are_equal("STEP_1", manager.menu_state.step)
        luassert.are_equal(0, #manager.selection_history)
    end)
end)
