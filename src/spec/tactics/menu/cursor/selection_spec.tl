local type _ = require("busted")
local luassert <const> = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local selection = require("src.tactics.menu.cursor.selection")
local event_bus = require("src.tactics.systems.event_bus")
local menu_context = require("src.tactics.menu.menu_context")
local input_helper = require("src.spec.input.input_helper")

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

    it("should cycle options using joypad vertical input when configured", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        (function(): selection.SelectionMenuDefinition
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

        local node = manager.menu_step.node as selection.SelectionMenuNode
        luassert.are_equal("A", node:get_selected_value())

        -- move down
        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_equal("B", node:get_selected_value())

        -- move up
        manager:update(input_helper.joypad({ dyp = -1 }))
        luassert.are_equal("A", node:get_selected_value())
    end)

    it("should handle increment/decrement commands directly", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
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

        local node = manager.menu_step.node as selection.SelectionMenuNode
        luassert.are_equal("A", node:get_selected_value())

        -- increment
        node:handle_command("increment_selection", { metadata = {} } as menu_context.MenuContext, ctx)
        luassert.are_equal("B", node:get_selected_value())

        -- decrement
        node:handle_command("decrement_selection", { metadata = {} } as menu_context.MenuContext, ctx)
        luassert.are_equal("A", node:get_selected_value())
    end)
end)
