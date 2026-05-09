local colors = require("src.tactics.colors")

---@alias PageFlipState "IDLE" | "PENDING_BEFORE" | "PENDING_AFTER" | "ANIMATING"
---@alias PageFlipDirection "forward" | "backward"

---@class PageFlipAnimator
---@field begin_flip fun(self: PageFlipAnimator, direction: PageFlipDirection, callback: fun())
---@field tick fun(self: PageFlipAnimator)
---@field is_active fun(self: PageFlipAnimator): boolean
---@field is_blocking_input fun(self: PageFlipAnimator): boolean
---@field draw fun(self: PageFlipAnimator, ui_manager: any, ui_context: any, draw_target_manager: any)

---@class PageFlipAnimatorImpl : PageFlipAnimator
---@field state PageFlipState
---@field direction PageFlipDirection | nil
---@field callback (fun()) | nil
---@field frame integer
---@field sprite_a userdata | nil
---@field sprite_b userdata | nil
local PageFlipAnimatorImpl = {}
PageFlipAnimatorImpl.__index = PageFlipAnimatorImpl

local math_util = require("src.tactics.math_util")

local page_flip_animator = {}

---@return PageFlipAnimator
function page_flip_animator.new()
    ---@type PageFlipAnimatorImpl
    local self = setmetatable({}, PageFlipAnimatorImpl)
    self.state = "IDLE"
    self.direction = nil
    self.callback = nil
    self.frame = 0
    return self
end

---@param direction PageFlipDirection
---@param callback fun()
function PageFlipAnimatorImpl:begin_flip(direction, callback)
    if self.state ~= "IDLE" then
        return
    end
    self.direction = direction
    self.callback = callback
    self.state = "PENDING_BEFORE"
end

function PageFlipAnimatorImpl:tick()
    if self.state ~= "ANIMATING" then
        return
    end
    self.frame = self.frame + 1
    if self.frame >= 40 then
        self.state = "IDLE"
        self.direction = nil
        self.callback = nil
        self.frame = 0
    end
end

---@return boolean
function PageFlipAnimatorImpl:is_active()
    return self.state ~= "IDLE"
end

---@return boolean
function PageFlipAnimatorImpl:is_blocking_input()
    return self.state ~= "IDLE"
end

function PageFlipAnimatorImpl:draw(ui_manager, ui_context, draw_target_manager)
    local w = STATIC_CONFIG.SCREEN_WIDTH
    local h = STATIC_CONFIG.SCREEN_HEIGHT
    if self.state == "PENDING_BEFORE" then
        -- Draw target needs power of 2 to use tline3d
        draw_target_manager:push_target(512, 512, 0, 0)
        ui_manager:draw(ui_context)
        self.sprite_a = draw_target_manager:pop_sprite()
        self.callback()
        self.state = "PENDING_AFTER"
    elseif self.state == "PENDING_AFTER" then
        ui_manager:calculate(ui_context)
        -- Draw target needs power of 2 to use tline3d
        draw_target_manager:push_target(512, 512, 0, 0)
        ui_manager:draw(ui_context)
        self.sprite_b = draw_target_manager:pop_sprite()
        self.frame = 0
        self.state = "ANIMATING"
    elseif self.state == "ANIMATING" then
        local half_w = w / 2
        local t = math_util.smoothstep(self.frame / 40)
        local visible_w = half_w * math.abs(math.cos(t * math.pi))

        sspr(self.sprite_a, 0, 0, half_w, h, 0, 0)
        sspr(self.sprite_b, half_w, 0, half_w, h, half_w, 0)

        if visible_w > 0 then
            local amplitude = 4
            local is_front = t < 0.5
            local src = is_front and self.sprite_a or self.sprite_b
            -- right_side: true when the turning page occupies half_w..half_w+visible_w
            local right_side = (self.direction == "forward") == is_front

            local x_start   = right_side and half_w or (half_w - visible_w)
            local x_end     = right_side and (half_w + visible_w) or half_w
            local leading_x = right_side and (half_w + visible_w) or (half_w - visible_w)

            local sin_factor = amplitude * math.sin(t)
            for x = math.floor(x_start), math.ceil(x_end) - 1 do
                local col_offset = math.abs(x - leading_x)
                local disp = sin_factor * (col_offset / half_w)
                local u
                if right_side then
                    if is_front then
                        -- forward+front: sprite_a right half, compressed
                        u = half_w + (x - half_w) * (half_w / visible_w)
                    else
                        -- backward+back: sprite_b left half, mirrored at spine
                        -- u = half_w - (x - half_w) * (half_w / visible_w)
                    end
                else
                    if is_front then
                        -- backward+front: sprite_a left half, compressed
                        -- u = half_w * (x - (half_w - visible_w)) / visible_w
                    else
                        -- forward+back: sprite_b left half, mirrored at spine
                        u = half_w - (half_w - x) * (half_w / visible_w)
                    end
                end
                tline3d(src, x, disp, x, h + disp, u, 0, u, h, 1, 1)
                -- line(x, disp, x, h+disp, colors.rainbow(x)[1])
            end
        end
    end
end

return page_flip_animator
