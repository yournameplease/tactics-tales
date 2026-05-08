local luassert = require("luassert")

local page_flip_animator = require("src.tactics.animation.page_flip_animator")

describe("tactics.animation.page_flip_animator", function()
    describe("begin_flip", function()
        it("transitions state from IDLE to PENDING_BEFORE", function()
            local animator = page_flip_animator.new()
            animator:begin_flip("forward", function() end)
            luassert.is_true(animator:is_active())
        end)

        it("is a no-op when already active", function()
            local animator = page_flip_animator.new()
            animator:begin_flip("forward", function() end)
            animator:begin_flip("backward", function() end)
            -- state should still reflect the first flip (forward)
            luassert.are_equal("forward", animator.direction)
        end)
    end)

    describe("is_blocking_input", function()
        it("returns false when IDLE", function()
            local animator = page_flip_animator.new()
            luassert.is_false(animator:is_blocking_input())
        end)

        it("returns true in PENDING_BEFORE", function()
            local animator = page_flip_animator.new()
            animator:begin_flip("forward", function() end)
            luassert.is_true(animator:is_blocking_input())
        end)

        it("returns true in PENDING_AFTER", function()
            local animator = page_flip_animator.new()
            animator.state = "PENDING_AFTER"
            luassert.is_true(animator:is_blocking_input())
        end)

        it("returns true in ANIMATING", function()
            local animator = page_flip_animator.new()
            animator.state = "ANIMATING"
            luassert.is_true(animator:is_blocking_input())
        end)
    end)

    describe("tick", function()
        it("advances frame counter during ANIMATING", function()
            local animator = page_flip_animator.new()
            animator.state = "ANIMATING"
            animator:tick()
            luassert.are_equal(1, animator.frame)
        end)

        it("transitions ANIMATING to IDLE at frame 40", function()
            local animator = page_flip_animator.new()
            animator.state = "ANIMATING"
            animator.frame = 39
            animator:tick()
            luassert.is_false(animator:is_active())
        end)

        it("does not advance frame outside ANIMATING", function()
            local animator = page_flip_animator.new()
            animator:begin_flip("forward", function() end)
            animator:tick()
            luassert.are_equal(0, animator.frame)
        end)
    end)

    describe("is_active", function()
        it("returns false when IDLE", function()
            local animator = page_flip_animator.new()
            luassert.is_false(animator:is_active())
        end)

        it("returns true after begin_flip", function()
            local animator = page_flip_animator.new()
            animator:begin_flip("forward", function() end)
            luassert.is_true(animator:is_active())
        end)
    end)
end)
