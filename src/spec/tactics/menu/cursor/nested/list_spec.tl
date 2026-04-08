local type _ = require("busted")
local luassert <const> = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local list = require("src.tactics.menu.cursor.nested.list")
local button = require("src.tactics.menu.cursor.button")
local event_bus = require("src.tactics.systems.event_bus")
local menu_context = require("src.tactics.menu.menu_context")
local menu_cursor = require("src.tactics.menu.menu_cursor")
local input_helper = require("src.spec.input.input_helper")

describe("tactics.menu.cursor.nested.list", function()
    local bus: event_bus.EventBus
    local ctx: menu_context.GameContext

    before_each(function()
        bus = event_bus.new()
        ctx = {} as menu_context.GameContext
    end)

    it("should navigate between children vertically in a column", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        list.column("test_list", function(_: menu_context.GameContext, _: menu_context.MenuContext): {menu_cursor.MenuNodeDefinition}
                            return {
                                button.builder("btn1"):with_text("Button 1"),
                                button.builder("btn2"):with_text("Button 2"),
                                button.builder("btn3"):with_text("Button 3")
                            }
                        end)
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node as list.NestedMenuNode
        luassert.are_equal(1, node.i)
        luassert.is_true(node.children[1].has_focus)
        luassert.is_false(node.children[2].has_focus)

        -- move down
        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_equal(2, node.i)
        luassert.is_false(node.children[1].has_focus)
        luassert.is_true(node.children[2].has_focus)

        -- move down again
        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_equal(3, node.i)

        -- no wrapping by default, should stay at 3
        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_equal(3, node.i)

        -- move up
        manager:update(input_helper.joypad({ dyp = -1 }))
        luassert.are_equal(2, node.i)
    end)

    it("should wrap navigation when configured", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        (function(): menu_cursor.MenuNodeDefinition
                            local def = list.column("test_list", function(_: menu_context.GameContext, _: menu_context.MenuContext): {menu_cursor.MenuNodeDefinition}
                                return {
                                    button.builder("btn1"),
                                    button.builder("btn2")
                                }
                            end)
                            def.wrap = true
                            return def
                        end)()
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node as list.NestedMenuNode
        luassert.are_equal(1, node.i)

        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_equal(2, node.i)

        -- wrap around to 1
        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_equal(1, node.i)

        -- move up from 1 wraps to 2
        manager:update(input_helper.joypad({ dyp = -1 }))
        luassert.are_equal(2, node.i)
    end)

    it("should navigate between children horizontally in a row", function()
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        list.row("test_list", function(_: menu_context.GameContext, _: menu_context.MenuContext): {menu_cursor.MenuNodeDefinition}
                            return {
                                button.builder("btn1"),
                                button.builder("btn2")
                            }
                        end)
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node as list.NestedMenuNode
        luassert.are_equal(1, node.i)

        -- move right
        manager:update(input_helper.joypad({ dxp = 1 }))
        luassert.are_equal(2, node.i)

        -- move left
        manager:update(input_helper.joypad({ dxp = -1 }))
        luassert.are_equal(1, node.i)
    end)
end)
