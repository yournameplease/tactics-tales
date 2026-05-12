require("src.spec.picotron_shim")
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
            ---@cast animator PageFlipAnimatorImpl
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
            ---@cast animator PageFlipAnimatorImpl
            animator.state = "PENDING_AFTER"
            luassert.is_true(animator:is_blocking_input())
        end)

        it("returns true in ANIMATING", function()
            local animator = page_flip_animator.new()
            ---@cast animator PageFlipAnimatorImpl
            animator.state = "ANIMATING"
            luassert.is_true(animator:is_blocking_input())
        end)
    end)

    describe("tick", function()
        it("advances frame counter during ANIMATING", function()
            local animator = page_flip_animator.new()
            ---@cast animator PageFlipAnimatorImpl
            animator.state = "ANIMATING"
            animator:tick()
            luassert.are_equal(1, animator.frame)
        end)

        it("transitions ANIMATING to IDLE at frame 40", function()
            local animator = page_flip_animator.new()
            ---@cast animator PageFlipAnimatorImpl
            animator.state = "ANIMATING"
            animator.frame = 39
            animator:tick()
            luassert.is_false(animator:is_active())
        end)

        it("does not advance frame outside ANIMATING", function()
            local animator = page_flip_animator.new()
            ---@cast animator PageFlipAnimatorImpl
            animator:begin_flip("forward", function() end)
            animator:tick()
            luassert.are_equal(0, animator.frame)
        end)
    end)

    describe("draw", function()
        -- ---------------------------------------------------------------------------
        -- Helpers
        -- ---------------------------------------------------------------------------

        local SPRITE_A = { id = "sprite_a" }
        local SPRITE_B = { id = "sprite_b" }

        ---@return table
        local function make_draw_target_manager()
            local dtm = { pushes = 0, pops = 0, sprites = { SPRITE_A, SPRITE_B } }
            function dtm:push_target(_w, _h, _x, _y)
                self.pushes = self.pushes + 1
            end
            function dtm:pop_sprite()
                self.pops = self.pops + 1
                return self.sprites[self.pops]
            end
            return dtm
        end

        ---@return table
        local function make_ui_manager()
            local mgr = { draw_calls = 0, calculate_calls = 0 }
            function mgr:draw(_ctx) self.draw_calls = self.draw_calls + 1 end
            function mgr:calculate(_ctx) self.calculate_calls = self.calculate_calls + 1 end
            return mgr
        end

        it("captures sprite_a and transitions to PENDING_AFTER in PENDING_BEFORE", function()
            local animator = page_flip_animator.new()
            ---@cast animator PageFlipAnimatorImpl
            local dtm = make_draw_target_manager()
            local ui = make_ui_manager()
            animator:begin_flip("forward", function() end)

            animator:draw(ui, {}, dtm)

            luassert.are_equal("PENDING_AFTER", animator.state)
            luassert.are_equal(SPRITE_A, animator.sprite_a)
        end)

        it("fires callback exactly once during PENDING_BEFORE", function()
            local animator = page_flip_animator.new()
            local count = 0
            animator:begin_flip("forward", function() count = count + 1 end)

            animator:draw(make_ui_manager(), {}, make_draw_target_manager())

            luassert.are_equal(1, count)
        end)

        it("captures sprite_b and transitions to ANIMATING in PENDING_AFTER", function()
            local animator = page_flip_animator.new()
            ---@cast animator PageFlipAnimatorImpl
            local dtm = make_draw_target_manager()
            local ui = make_ui_manager()
            animator:begin_flip("forward", function() end)
            animator:draw(ui, {}, dtm)  -- PENDING_BEFORE → PENDING_AFTER

            animator:draw(ui, {}, dtm)  -- PENDING_AFTER → ANIMATING

            luassert.are_equal("ANIMATING", animator.state)
            luassert.are_equal(SPRITE_B, animator.sprite_b)
            luassert.are_equal(0, animator.frame)
        end)

        it("keeps push/pop balanced across both frames", function()
            local animator = page_flip_animator.new()
            local dtm = make_draw_target_manager()
            local ui = make_ui_manager()
            animator:begin_flip("forward", function() end)
            animator:draw(ui, {}, dtm)
            animator:draw(ui, {}, dtm)

            luassert.are_equal(dtm.pops, dtm.pushes)
        end)

        it("calls ui_manager:calculate before capturing sprite_b in PENDING_AFTER", function()
            local animator = page_flip_animator.new()
            local ui = make_ui_manager()
            animator:begin_flip("forward", function() end)
            animator:draw(ui, {}, make_draw_target_manager())

            animator:draw(ui, {}, make_draw_target_manager())

            luassert.are_equal(1, ui.calculate_calls)
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
