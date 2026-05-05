local luassert = require("luassert")

local menu_manager = require("src.tactics.menu.menu_manager")
local list = require("src.tactics.menu.cursor.nested.list")
local button = require("src.tactics.menu.cursor.button")
local selection = require("src.tactics.menu.cursor.selection")
local event_bus = require("src.tactics.systems.event_bus")
local input_helper = require("src.spec.input.input_helper")

describe("tactics.menu.cursor.nested.list", function()
    local bus
    local ctx

    before_each(function()
        bus = event_bus.new()
        ctx = {}
    end)

    it("should navigate between children vertically in a column", function()
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        list.column("test_list", function(_gc, _mc)
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

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node
        ---@cast node NestedMenuNode
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
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        (function()
                            local def = list.column("test_list", function(_gc, _mc)
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

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node
        ---@cast node NestedMenuNode
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
        local menu_defs = {
            ["TEST_MENU"] = {
                initial_step = "STEP_1",
                steps = {
                    ["STEP_1"] = menu_manager.definition.step.of_node(
                        list.row("test_list", function(_gc, _mc)
                            return {
                                button.builder("btn1"),
                                button.builder("btn2")
                            }
                        end)
                    )
                }
            }
        }

        local manager = menu_manager.new(menu_defs, ctx, bus)
        manager:set_menu("TEST_MENU")

        local node = manager.menu_step.node
        ---@cast node NestedMenuNode
        luassert.are_equal(1, node.i)

        -- move right
        manager:update(input_helper.joypad({ dxp = 1 }))
        luassert.are_equal(2, node.i)

        -- move left
        manager:update(input_helper.joypad({ dxp = -1 }))
        luassert.are_equal(1, node.i)
    end)

    describe("serialize/deserialize", function()
        it("should serialize the focused index", function()
            local menu_defs = {
                ["TEST_MENU"] = {
                    initial_step = "STEP_1",
                    steps = {
                        ["STEP_1"] = menu_manager.definition.step.of_node(
                            list.column("test_list", function(_gc, _mc)
                                return {
                                    button.builder("btn1"),
                                    button.builder("btn2"),
                                    button.builder("btn3"),
                                }
                            end)
                        )
                    }
                }
            }

            local manager = menu_manager.new(menu_defs, ctx, bus)
            manager:set_menu("TEST_MENU")

            -- navigate to index 3
            manager:update(input_helper.joypad({ dyp = 1 }))
            manager:update(input_helper.joypad({ dyp = 1 }))
            luassert.are_equal(3, (manager.menu_step.node --[[@as NestedMenuNode]]).i)

            local ser = manager:serialize()
            luassert.are_equal("list", ser.node.state.type)
            luassert.are_equal(3, (ser.node.state --[[@as SerializedNestedMenuNodeState]]).i)
        end)

        it("should deserialize the focused index", function()
            local menu_defs = {
                ["TEST_MENU"] = {
                    initial_step = "STEP_1",
                    steps = {
                        ["STEP_1"] = menu_manager.definition.step.of_node(
                            list.column("test_list", function(_gc, _mc)
                                return {
                                    button.builder("btn1"),
                                    button.builder("btn2"),
                                    button.builder("btn3"),
                                }
                            end)
                        )
                    }
                }
            }

            local manager = menu_manager.new(menu_defs, ctx, bus)
            manager:set_menu("TEST_MENU")

            -- navigate to index 2 and serialize
            manager:update(input_helper.joypad({ dyp = 1 }))
            local ser = manager:serialize()
            luassert.are_equal(2, (ser.node.state --[[@as SerializedNestedMenuNodeState]]).i)

            -- create a new manager and deserialize
            local manager2 = menu_manager.new(menu_defs, ctx, bus)
            manager2:set_menu("TEST_MENU")
            manager2.menu_step.node:deserialize(ser.node.state, ser.node.data)

            luassert.are_equal(2, (manager2.menu_step.node --[[@as NestedMenuNode]]).i)
        end)

        it("should round-trip a list containing selection children", function()
            local menu_defs = {
                ["TEST_MENU"] = {
                    initial_step = "STEP_1",
                    steps = {
                        ["STEP_1"] = menu_manager.definition.step.of_node(
                            list.column("test_list", function(_gc, _mc)
                                return {
                                    button.builder("btn1"),
                                    selection.row("sel1")
                                        :with_key("color")
                                        :with_static_options({ "red", "green", "blue" }),
                                }
                            end)
                        )
                    }
                }
            }

            local manager = menu_manager.new(menu_defs, ctx, bus)
            manager:set_menu("TEST_MENU")

            -- navigate to selection child and advance it
            manager:update(input_helper.joypad({ dyp = 1 }))
            manager:update(input_helper.joypad({ dxp = 1 }))
            manager:update(input_helper.joypad({ dxp = 1 }))

            local node = manager.menu_step.node
            ---@cast node NestedMenuNode
            luassert.are_equal(2, node.i)
            luassert.are_equal("blue", (node.children[2] --[[@as SelectionMenuNode]]):get_selected_value())

            local ser = manager:serialize()
            luassert.are_equal(2, (ser.node.state --[[@as SerializedNestedMenuNodeState]]).i)
            luassert.are_equal("blue", ser.node.data["color"])

            -- new manager, restore
            local manager2 = menu_manager.new(menu_defs, ctx, bus)
            manager2:set_menu("TEST_MENU")
            manager2.menu_step.node:deserialize(ser.node.state, ser.node.data)

            local node2 = manager2.menu_step.node
            ---@cast node2 NestedMenuNode
            luassert.are_equal(2, node2.i)
            luassert.are_equal("blue", (node2.children[2] --[[@as SelectionMenuNode]]):get_selected_value())
        end)
    end)
end)
