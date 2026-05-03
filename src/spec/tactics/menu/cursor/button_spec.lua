local luassert = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local button = require("src.tactics.menu.cursor.button")
local event_bus = require("src.tactics.systems.event_bus")
local menu_context = require("src.tactics.menu.menu_context")
local input_helper = require("src.spec.input.input_helper")

describe("tactics.menu.cursor.button", function()
    local bus
    local ctx

    before_each(function()
        bus = event_bus.new()
        ctx = {}
    end)

    it("should trigger a handler when pressed via joypad", function()
        local handler_called = false
        local handler_value = nil

        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                handlers = {
                    ["test_handler"] = function(_gc, _mc, value)
                        handler_called = true
                        handler_value = value
                        return nil
                    end
                },
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

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        manager:update(input_helper.joypad({ a = true, ap = true }))

        luassert.is_true(handler_called)
        luassert.are_equal("test_value", handler_value)
    end)

    it("should navigate to next state when configured", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                handlers = {},
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

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        manager:update(input_helper.joypad({ ap = true }))

        luassert.are_equal("STEP_2", manager.menu_state.step)
    end)

    it("should go back when configured", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                handlers = {},
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

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        -- advance to STEP_2
        manager:update(input_helper.joypad({ ap = true }))
        luassert.are_equal("STEP_2", manager.menu_state.step)

        -- go back to STEP_1
        manager:update(input_helper.joypad({ ap = true }))
        luassert.are_equal("STEP_1", manager.menu_state.step)
    end)

    it("should finish menu when as_final_step is set", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                handlers = {},
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1"):as_final_step()
                    ):with_action("BUTTON_A", { command = "select" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        manager:update(input_helper.joypad({ ap = true }))
        luassert.is_nil(manager.menu_state.menu_id)
    end)

    it("should handle multiple commands with different handlers", function()
        local select_called = false
        local menu_called = false

        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                handlers = {
                    ["select_h"] = function(_gc, _mc, _v)
                        select_called = true
                        return nil
                    end,
                    ["menu_h"] = function(_gc, _mc, _v)
                        menu_called = true
                        return nil
                    end
                },
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1")
                            :handle_action("select", "select_h")
                            :handle_action("menu", "menu_h")
                    ):with_action("BUTTON_A", { command = "select" })
                     :with_action("BUTTON_B", { command = "menu" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        -- select
        manager:update(input_helper.joypad({ ap = true }))
        luassert.is_true(select_called)
        luassert.is_false(menu_called)

        -- menu
        manager:update(input_helper.joypad({ bp = true }))
        luassert.is_true(menu_called)
    end)

    it("should handle complex handler responses (recompute and navigate)", function()
        local recompute_count = 0

        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                handlers = {
                    ["recompute_h"] = function(_gc, _mc, _v)
                        return menu_manager.menu_handler.then_recompute()
                    end,
                    ["navigate_h"] = function(_gc, _mc, _v)
                        return menu_manager.menu_handler.then_navigate("STEP_2")
                    end
                },
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        button.builder("btn1")
                            :handle_action("select", "recompute_h")
                            :handle_action("menu", "navigate_h")
                    ):with_action("BUTTON_A", { command = "select" })
                     :with_action("BUTTON_B", { command = "menu" }),
                    ["STEP_2"] = menu_manager.definition.step.of_node(
                        button.builder("btn2")
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        -- hook into recompute
        local original_recompute = manager.menu_step.node.recompute
        manager.menu_step.node.recompute = function(self, g, m)
            recompute_count = recompute_count + 1
            original_recompute(self, g, m)
        end

        -- trigger recompute
        manager:update(input_helper.joypad({ ap = true }))
        luassert.are_equal(1, recompute_count)

        -- trigger navigate
        manager:update(input_helper.joypad({ bp = true }))
        luassert.are_equal("STEP_2", manager.menu_state.step)
    end)

    describe("serialize/deserialize", function()
        it("should serialize to empty state and data", function()
            local menu_defs = {
                ["TEST_MENU"] = {
                    initial_step = "STEP_1",
                    handlers = {},
                    steps = {
                        ["STEP_1"] = menu_manager.definition.step.of_node(
                            button.builder("btn1"):with_text("OK")
                        )
                    }
                }
            }

            local manager = menu_manager.new(menu_defs, ctx, bus)
            manager:set_menu("TEST_MENU")

            local ser = manager:serialize()
            luassert.is_nil(ser.node.state)
            luassert.are_same({}, ser.node.data)
        end)

        it("should deserialize without error or state change", function()
            local menu_defs = {
                ["TEST_MENU"] = {
                    initial_step = "STEP_1",
                    handlers = {},
                    steps = {
                        ["STEP_1"] = menu_manager.definition.step.of_node(
                            button.builder("btn1"):with_text("OK")
                        )
                    }
                }
            }

            local manager = menu_manager.new(menu_defs, ctx, bus)
            manager:set_menu("TEST_MENU")

            -- deserialize with empty data; should be a no-op
            manager.menu_step.node:deserialize(nil, {})

            local ser = manager:serialize()
            luassert.is_nil(ser.node.state)
        end)
    end)
end)
