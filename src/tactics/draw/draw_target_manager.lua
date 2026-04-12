---@brief
--- Manages off-screen drawing targets (render textures).
--- Allows for pre-rendering sprites to improve performance.

require("profiler")
local colors = require("src.tactics.colors")

---@class DrawTargetEntry
---@field ud userdata
---@field w integer
---@field h integer
---@field camera_x integer
---@field camera_y integer

---@class DrawTargetManager
---@field package targets DrawTargetEntry[]
---@field package current_target DrawTargetEntry|nil
local DrawTargetManager = {}
DrawTargetManager.__index = DrawTargetManager

--- Apply the current draw target and camera state to Picotron.
function DrawTargetManager:apply_current_target()
    if self.current_target ~= nil then
        set_draw_target(self.current_target.ud)
        set_camera(self.current_target.camera_x, self.current_target.camera_y)
    else
        set_draw_target()
        reset_camera()
    end
end

--- Push a new off-screen draw target of the given size onto the stack.
---@param w integer Width of the new target.
---@param h integer Height of the new target.
---@param d_x integer X offset for the camera (stored negated).
---@param d_y integer Y offset for the camera (stored negated).
function DrawTargetManager:push_target(w, h, d_x, d_y)
    local ud = userdata("u8", w, h)
    local new_target = {
        ud = ud,
        w = w,
        h = h,
        camera_x = -d_x or 0,
        camera_y = -d_y or 0,
    }

    if self.current_target ~= nil then
        table.insert(self.targets, self.current_target)
    end
    self.current_target = new_target
    self:apply_current_target()
    if DYNAMIC_CONFIG.draw_target_debug then
        local color = colors.rainbow(#self.targets)
        rrectfill(d_x, d_y, w, h, 0, color[2])
    end
end

--- Push a duplicate of the current target onto the stack, preserving its size and camera.
function DrawTargetManager:duplicate_target()
    self:push_target(
        self.current_target.w,
        self.current_target.h,
        -self.current_target.camera_x,
        -self.current_target.camera_y
    )
end

--- Pop the current draw target, restore the previous one, and draw the popped target at (x, y).
---@param x integer
---@param y integer
function DrawTargetManager:draw(x, y)
    assert(self.current_target ~= nil)
    local prev_target = self.current_target
    ---@cast prev_target DrawTargetEntry
    self.current_target = pop(self.targets)
    self:apply_current_target()

    -- sspr(prev_target.ud, 0, 0, prev_target.w, prev_target.h, x, y)
    spr(prev_target.ud, x, y)
    if DYNAMIC_CONFIG.draw_target_debug then
        local color = colors.rainbow(#self.targets + (self.current_target == nil and 0 or 1))
        rrect(x, y, prev_target.w, prev_target.h, 0, color[1])
    end
end

--- Pop the current draw target, restore the previous one, and return the userdata.
---@return userdata
function DrawTargetManager:pop_sprite()
    assert(self.current_target ~= nil)
    local prev_target = self.current_target
    ---@cast prev_target DrawTargetEntry
    self.current_target = pop(self.targets)
    self:apply_current_target()
    return prev_target.ud
end

local draw_target_manager = {
    DrawTargetManager = DrawTargetManager,
}

--- Create a new DrawTargetManager instance.
---@return DrawTargetManager
function draw_target_manager.new()
    ---@type DrawTargetManager
    local self = setmetatable({}, DrawTargetManager)
    self.targets = {}
    return self
end

return draw_target_manager
