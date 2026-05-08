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
local PageFlipAnimatorImpl = {}
PageFlipAnimatorImpl.__index = PageFlipAnimatorImpl

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

function PageFlipAnimatorImpl:draw(_ui_manager, _ui_context, _draw_target_manager)
end

return page_flip_animator
