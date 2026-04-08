local type _ = require("busted")
local luassert <const> = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local button = require("src.tactics.menu.cursor.button")
local event_bus = require("src.tactics.systems.event_bus")
local menu_context = require("src.tactics.menu.menu_context")
local input_helper = require("src.spec.input.input_helper")

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

        manager:update(input_helper.joypad({ a = true, ap = true }))

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

        manager:update(input_helper.joypad({ ap = true }))

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

        -- advance to STEP_2
        manager:update(input_helper.joypad({ ap = true }))
        luassert.are_equal("STEP_2", manager.menu_state.step)

        -- go back to STEP_1
        manager:update(input_helper.joypad({ ap = true }))
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

        manager:update(input_helper.joypad({ ap = true }))
        luassert.is_nil(manager.menu_state.menu_id)
    end)

    it("should handle multiple commands with different handlers", function()
        local select_called = false
        local menu_called = false

        local handlers: { string: menu_manager.MenuHandler } = {
            ["select_h"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, _: any): menu_manager.menu_handler.MenuHandlerPostHandling
                select_called = true
                return nil
            end,
            ["menu_h"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, _: any): menu_manager.menu_handler.MenuHandlerPostHandling
                menu_called = true
                return nil
            end
        }

        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
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

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
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
        local handlers: { string: menu_manager.MenuHandler } = {
            ["recompute_h"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, _: any): menu_manager.menu_handler.MenuHandlerPostHandling
                return menu_manager.menu_handler.then_recompute()
            end,
            ["navigate_h"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, _: any): menu_manager.menu_handler.MenuHandlerPostHandling
                return menu_manager.menu_handler.then_navigate("STEP_2")
            end
        }

        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
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

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")
        
        -- hook into recompute
        local original_recompute = manager.menu_step.node.recompute
        manager.menu_step.node.recompute = function(self: button.ButtonCursor, g: menu_context.GameContext, m: menu_context.MenuContext)
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
end)
