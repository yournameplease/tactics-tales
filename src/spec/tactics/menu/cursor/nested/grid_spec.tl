local type _ = require("busted")
local luassert <const> = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local grid = require("src.tactics.menu.cursor.nested.grid")
local button = require("src.tactics.menu.cursor.button")
local event_bus = require("src.tactics.systems.event_bus")
local menu_context = require("src.tactics.menu.menu_context")
local point = require("src.tactics.util.point")
local Point = point.Point
local input_helper = require("src.spec.input.input_helper")

describe("tactics.menu.cursor.nested.grid", function()
    local bus: event_bus.EventBus
    local ctx: menu_context.GameContext

    before_each(function()
        bus = event_bus.new()
        ctx = {} as menu_context.GameContext
    end)

    it("should navigate in 2D using joypad", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        grid.grid("test_grid", 5, 5)
                            :with_common_child(button.builder("common_btn"))
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node as grid.NestedGridNode
        luassert.are_equal(0, node.point.x)
        luassert.are_equal(0, node.point.y)

        -- move right
        manager:update(input_helper.joypad({ dxp = 1 }))
        luassert.are_equal(1, node.point.x)
        luassert.are_equal(0, node.point.y)

        -- move down
        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_equal(1, node.point.x)
        luassert.are_equal(1, node.point.y)

        -- move diagonal
        manager:update(input_helper.joypad({ dxp = 1, dyp = 1 }))
        luassert.are_equal(2, node.point.x)
        luassert.are_equal(2, node.point.y)
    end)

    it("should filter children based on point", function()
        local button1_called = false
        local button2_called = false

        local handlers: { string: menu_manager.MenuHandler } = {
            ["h1"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, _: any): menu_manager.menu_handler.MenuHandlerPostHandling
                button1_called = true
                return nil
            end,
            ["h2"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, _: any): menu_manager.menu_handler.MenuHandlerPostHandling
                button2_called = true
                return nil
            end
        }

        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        grid.grid("test_grid", 2, 2)
                            :with_child(
                                function(p: Point, _: menu_context.GameContext, _: menu_context.MenuContext): boolean
                                    return p.x == 0 and p.y == 0
                                end,
                                button.builder("btn00"):handle_action("select", "h1")
                            )
                            :with_child(
                                function(p: Point, _: menu_context.GameContext, _: menu_context.MenuContext): boolean
                                    return p.x == 1 and p.y == 1
                                end,
                                button.builder("btn11"):handle_action("select", "h2")
                            )
                    ):with_action("BUTTON_A", { command = "select" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")

        -- at (0,0), trigger btn00
        manager:update(input_helper.joypad({ a = true, ap = true }))
        luassert.is_true(button1_called)
        luassert.is_false(button2_called)

        -- reset
        button1_called = false

        -- move to (1,1)
        manager:update(input_helper.joypad({ dxp = 1, dyp = 1 }))
        
        -- trigger btn11
        manager:update(input_helper.joypad({ a = true, ap = true }))
        luassert.is_false(button1_called)
        luassert.is_true(button2_called)
    end)

    it("should start at initial point if configured", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        grid.grid("test_grid", 5, 5)
                            :with_common_child(button.builder("common_btn"))
                            :with_initial_point(function(_: menu_context.GameContext, _: menu_context.MenuContext): Point
                                return point.of(3, 4)
                            end)
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node as grid.NestedGridNode
        luassert.are_equal(3, node.point.x)
        luassert.are_equal(4, node.point.y)
    end)
end)
