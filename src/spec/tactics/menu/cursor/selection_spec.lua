local luassert = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local selection = require("src.tactics.menu.cursor.selection")
local event_bus = require("src.tactics.systems.event_bus")
local input_helper = require("src.spec.input.input_helper")

describe("tactics.menu.cursor.selection", function()
    local bus
    local ctx

    before_each(function()
        bus = event_bus.new()
        ctx = {}
    end)

    it("should cycle options using joypad horizontal input", function()
        local menu_defs = {
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

        local node = manager.menu_step.node
        luassert.are_equal("A", node:get_selected_value())

        -- move right
        manager:update(input_helper.joypad({ dxp = 1 }))
        luassert.are_equal("B", node:get_selected_value())

        -- move right again
        manager:update(input_helper.joypad({ dxp = 1 }))
        luassert.are_equal("C", node:get_selected_value())

        -- wrap around
        manager:update(input_helper.joypad({ dxp = 1 }))
        luassert.are_equal("A", node:get_selected_value())

        -- move left
        manager:update(input_helper.joypad({ dxp = -1 }))
        luassert.are_equal("C", node:get_selected_value())
    end)

    it("should deserialize initial data correctly", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        selection.row("test_sel")
                            :with_key("my_key")
                            :with_static_options({"A", "B", "C"})
                    ):with_initial_data(function(_gc, _mc)
                        return { ["my_key"] = "B" }
                    end)
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node
        luassert.are_equal("B", node:get_selected_value())
    end)

    it("should serialize selected value", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        selection.row("test_sel")
                            :with_key("my_key")
                            :with_static_options({"A", "B", "C"})
                    ):with_action("BUTTON_A", { command = "select" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        manager:update(input_helper.joypad({ dxp = 1 }))

        local ser = manager:serialize()
        luassert.are_equal("B", ser.node.data["my_key"])
    end)

    it("should serialize and deserialize a round-trip", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        selection.row("test_sel")
                            :with_key("my_key")
                            :with_static_options({"A", "B", "C"})
                            :with_wrap(true)
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        -- advance to "C"
        manager:update(input_helper.joypad({ dxp = 1 }))
        manager:update(input_helper.joypad({ dxp = 1 }))
        luassert.are_equal("C", manager.menu_step.node:get_selected_value())

        local ser = manager:serialize()

        -- new manager, deserialize
        local manager2 = menu_manager.new(menu_defs, {}, ctx, bus)
        manager2:set_menu("TEST_MENU")
        manager2.menu_step.node:deserialize(ser.node.state, ser.node.data)

        luassert.are_equal("C", manager2.menu_step.node:get_selected_value())
    end)

    it("should cycle options using joypad vertical input when configured", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        (function()
                            local def = selection.row("test_sel")
                                :with_static_options({"A", "B", "C"})
                            def.direction = "vertical"
                            return def
                        end)()
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node
        luassert.are_equal("A", node:get_selected_value())

        -- move down
        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_equal("B", node:get_selected_value())

        -- move up
        manager:update(input_helper.joypad({ dyp = -1 }))
        luassert.are_equal("A", node:get_selected_value())
    end)

    it("should handle increment/decrement commands directly", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        selection.row("test_sel")
                            :with_static_options({"A", "B", "C"})
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node
        luassert.are_equal("A", node:get_selected_value())

        -- increment
        node:handle_command("increment_selection", { metadata = {} }, ctx)
        luassert.are_equal("B", node:get_selected_value())

        -- decrement
        node:handle_command("decrement_selection", { metadata = {} }, ctx)
        luassert.are_equal("A", node:get_selected_value())
    end)
end)
