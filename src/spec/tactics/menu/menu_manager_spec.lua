local luassert = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local button = require("src.tactics.menu.cursor.button")
local event_bus = require("src.tactics.systems.event_bus")
local input_helper = require("src.spec.input.input_helper")

describe("tactics.menu.menu_manager", function()
    local bus
    local ctx
    local original_peektext
    local original_readtext

    before_each(function()
        bus = event_bus.new()
        ctx = {}
        original_peektext = _G.peektext
        original_readtext = _G.readtext
    end)

    after_each(function()
        _G.peektext = original_peektext
        _G.readtext = original_readtext
    end)

    local function mock_text_input(chars)
        local queue = { table.unpack(chars) }
        _G.peektext = function() return #queue > 0 end
        _G.readtext = function()
            return table.remove(queue, 1)
        end
    end

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

    it("keyboard_handler receives concatenated text from peektext/readtext", function()
        local received_text
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1"):with_text("key")
                    ):with_keyboard_handler("record_text"),
                }
            }
        }
        local handlers = {
            record_text = function(_svc, _data, _ctx, text)
                received_text = text
                return nil
            end,
        }

        mock_text_input({"h", "i"})

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")
        manager:update(input_helper.joypad({}))

        luassert.are_equal("hi", received_text)
    end)

    it("keyboard_handler returning nil suppresses joypad input", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1"):advance_to("STEP_2")
                    ):with_keyboard_handler("noop_handler")
                     :with_action("BUTTON_A", { command = "select" }),
                    ["STEP_2"] = menu_manager.definition.step.of_node(
                        button.builder("btn2"):with_text("done")
                    ),
                }
            }
        }
        local handlers = {
            noop_handler = function(_svc, _data, _ctx, _text)
                return nil
            end,
        }

        mock_text_input({"a"})

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")
        manager:update(input_helper.joypad({ ap = true }))

        luassert.are_equal("STEP_1", manager.menu_state.step)
    end)

    it("keyboard_handler returning true allows joypad input on the same frame", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1"):advance_to("STEP_2")
                    ):with_keyboard_handler("passthrough_handler")
                     :with_action("BUTTON_A", { command = "select" }),
                    ["STEP_2"] = menu_manager.definition.step.of_node(
                        button.builder("btn2"):with_text("done")
                    ),
                }
            }
        }
        local handlers = {
            passthrough_handler = function(_svc, _data, _ctx, _text)
                return true
            end,
        }

        mock_text_input({"a"})

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")
        manager:update(input_helper.joypad({ ap = true }))

        luassert.are_equal("STEP_2", manager.menu_state.step)
    end)
end)
