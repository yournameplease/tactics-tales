local luassert = require("luassert")

local draw_target_manager = require("src.tactics.draw.draw_target_manager")

describe("tactics.draw.draw_target_manager", function()
    local manager

    before_each(function()
        manager = draw_target_manager.new()
    end)

    describe("push_target", function()
        it("should set current_target with correct dimensions", function()
            manager:push_target(32, 16, 0, 0)
            local impl = manager
            luassert.are_equal(32, impl.current_target.w)
            luassert.are_equal(16, impl.current_target.h)
        end)

        it("should start with an empty stack", function()
            manager:push_target(32, 16, 0, 0)
            local impl = manager
            luassert.are_equal(0, #impl.targets)
        end)

        it("should push the previous target onto the stack", function()
            manager:push_target(32, 16, 0, 0)
            manager:push_target(8, 8, 0, 0)
            local impl = manager
            luassert.are_equal(1, #impl.targets)
            luassert.are_equal(32, impl.targets[1].w)
            luassert.are_equal(16, impl.targets[1].h)
        end)

        it("should store negated camera offsets", function()
            manager:push_target(32, 16, 4, 8)
            local impl = manager
            luassert.are_equal(-4, impl.current_target.camera_x)
            luassert.are_equal(-8, impl.current_target.camera_y)
        end)
    end)

    describe("duplicate_target", function()
        it("should push a new target with the same dimensions as the current one", function()
            manager:push_target(32, 16, 0, 0)
            manager:duplicate_target()
            local impl = manager
            luassert.are_equal(32, impl.current_target.w)
            luassert.are_equal(16, impl.current_target.h)
            luassert.are_equal(1, #impl.targets)
        end)
    end)

    describe("pop_sprite", function()
        it("should return the userdata of the current target", function()
            manager:push_target(32, 16, 0, 0)
            local impl = manager
            local expected_ud = impl.current_target.ud
            local result = manager:pop_sprite()
            luassert.are_equal(expected_ud, result)
        end)

        it("should restore the previous target after popping", function()
            manager:push_target(32, 16, 0, 0)
            manager:push_target(8, 8, 0, 0)
            manager:pop_sprite()
            local impl = manager
            luassert.are_equal(32, impl.current_target.w)
            luassert.are_equal(16, impl.current_target.h)
            luassert.are_equal(0, #impl.targets)
        end)

        it("should leave current_target nil when stack is empty", function()
            manager:push_target(32, 16, 0, 0)
            manager:pop_sprite()
            local impl = manager
            luassert.is_nil(impl.current_target)
        end)
    end)

    describe("draw", function()
        it("should restore the previous target after drawing", function()
            manager:push_target(32, 16, 0, 0)
            manager:push_target(8, 8, 0, 0)
            manager:draw(0, 0)
            local impl = manager
            luassert.are_equal(32, impl.current_target.w)
            luassert.are_equal(16, impl.current_target.h)
        end)

        it("should leave current_target nil when stack is empty", function()
            manager:push_target(32, 16, 0, 0)
            manager:draw(0, 0)
            local impl = manager
            luassert.is_nil(impl.current_target)
        end)
    end)
end)
