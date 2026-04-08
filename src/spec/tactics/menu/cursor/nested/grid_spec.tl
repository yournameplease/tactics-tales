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

    it("should extend path when moving in grid with pathfinding configured", function()
        local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        grid.grid("test_grid", 16, 16)
                            :with_common_child(button.builder("common_btn"))
                            :with_path_anchor(function(_: menu_context.GameContext, _: menu_context.MenuContext): Point
                                return point.of(0, 0)
                            end)
                            :with_path_length(function(_: menu_context.GameContext, _: menu_context.MenuContext): integer
                                return 5
                            end)
                            :with_tile_highlights(function(_: menu_context.GameContext, _: menu_context.MenuContext): Userdata
                                local tiles = pt.userdata("u8", 16, 16)
                                for y=0,15 do
                                    for x=0,15 do
                                        tiles:set(x, y, 3)
                                    end
                                end
                                return tiles
                            end)
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node as grid.NestedGridNode
        luassert.are_same({point.of(0, 0)}, node.path)

        -- move right
        manager:update(input_helper.joypad({ dxp = 1 }))
        luassert.are_same({point.of(0, 0), point.of(1, 0)}, node.path)

        -- move down
        manager:update(input_helper.joypad({ dyp = 1 }))
        luassert.are_same({point.of(0, 0), point.of(1, 0), point.of(1, 1)}, node.path)
    end)

    it("should serialize and deserialize point and path", function()
        local HIGHLIGHT = require("src.tactics.constants").HIGHLIGHT
        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        grid.grid("test_grid", 16, 16)
                            :with_common_child(button.builder("common_btn"))
                            :with_path_anchor(function(_: menu_context.GameContext, _: menu_context.MenuContext): Point
                                return point.of(0, 0)
                            end)
                            :with_path_length(function(_: menu_context.GameContext, _: menu_context.MenuContext): integer
                                return 5
                            end)
                            :with_tile_highlights(function(_: menu_context.GameContext, _: menu_context.MenuContext): Userdata
                                local tiles = pt.userdata("u8", 16, 16)
                                for y=0,15 do
                                    for x=0,15 do
                                        tiles:set(x, y, 3)
                                    end
                                end
                                return tiles
                            end)
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, {}, ctx, bus)
        manager:set_menu("TEST_MENU")

        -- move to (2, 1)
        manager:update(input_helper.joypad({ dxp = 1 }))
        manager:update(input_helper.joypad({ dxp = 1 }))
        manager:update(input_helper.joypad({ dyp = 1 }))
        
        local node = manager.menu_step.node as grid.NestedGridNode
        luassert.are_equal(2, node.point.x)
        luassert.are_equal(1, node.point.y)
        luassert.are_equal(4, #node.path)

        -- serialize
        local serialized = manager:serialize()
        
        -- create new manager and deserialize
        local manager2 = menu_manager.new(menu_defs, {}, ctx, bus)
        manager2:set_menu("TEST_MENU")
        manager2.menu_step.node:deserialize(serialized.node.state, serialized.node.data)

        local node2 = manager2.menu_step.node as grid.NestedGridNode
        luassert.are_equal(2, node2.point.x)
        luassert.are_equal(1, node2.point.y)
        luassert.are_same(node.path, node2.path)
    end)

    it("should filter multiple children based on handler response (input filtering)", function()
        local action_called = false
        local cycle_called = false

        local handlers: { string: menu_manager.MenuHandler } = {
            ["action_h"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, _: any): menu_manager.menu_handler.MenuHandlerPostHandling
                action_called = true
                return nil
            end,
            ["cycle_h"] = function(_: menu_context.GameContext, _: {string: any}, _: menu_context.MenuContext, _: any): menu_manager.menu_handler.MenuHandlerPostHandling
                cycle_called = true
                return nil
            end
        }

        local menu_defs: { string: menu_manager.MenuDefinition } = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        grid.grid("test_grid", 5, 5)
                            :with_common_child(
                                button.builder("action_btn")
                                    :handle_action("select", "action_h")
                            )
                            :with_common_child(
                                button.builder("cycle_btn")
                                    :handle_action("cycle_right", "cycle_h")
                            )
                    ):with_action("BUTTON_A", { command = "select" })
                     :with_action("SHOULDER_R", { command = "cycle_right" })
                }
            }
        }

        local manager = menu_manager.new(menu_defs, handlers, ctx, bus)
        manager:set_menu("TEST_MENU")

        -- trigger action
        manager:update(input_helper.joypad({ ap = true }))
        luassert.is_true(action_called)
        luassert.is_false(cycle_called)

        -- reset
        action_called = false

        -- trigger cycle
        manager:update(input_helper.joypad({ rp = true }))
        luassert.is_false(action_called)
        luassert.is_true(cycle_called)
    end)
end)
