---@brief
--- Manages sprite animations, including path-based, offset, and global
--- animations for characters.

local point = require("src.tactics.util.point")
local lists = require("src.tactics.util.lists")
require("src.tactics.character.animation_data")

---@class AnimatedSpriteData
---@field current_frame AnimationFrameData
---@field playing boolean

---@alias AnimationType "path" | "offset" | "global"

---@class AnimationInstance
---@field type AnimationType
---@field playing boolean
---@field animated_object AnimatedSpriteData
local AnimationInstance = {}


function AnimationInstance:tick() end

---@param global_frame integer
---@return AnimationFrameName
function AnimationInstance:get_sprite_frame_name(global_frame) end

---@param global_frame integer
---@return Point
function AnimationInstance:get_animation_offset(global_frame) end

---@param global_frame integer
---@return CardinalDirection
function AnimationInstance:get_animation_facing(global_frame) end

---@class SpriteFrame
---@field sprite_name AnimationFrameName
---@field duration integer

---@class SpriteFrameData
---@field duration integer
---@field sprite_frames SpriteFrame[]
local SpriteFrameData = {}
SpriteFrameData.__index = SpriteFrameData

local sprite_frame_data = {}

--- Create a new SpriteFrameData
---@param sprite_frames SpriteFrame[]
---@return SpriteFrameData
function sprite_frame_data.new(sprite_frames)
    local duration = 0
    for _, v in ipairs(sprite_frames) do
        duration = duration + v.duration
    end
    
    return setmetatable({
        duration = duration,
        sprite_frames = sprite_frames
    }, SpriteFrameData)
end

--- get the AnimationFrameName at a given frame
---@param frame integer
---@return AnimationFrameName
function SpriteFrameData:get_at_frame(frame)
    local total_frames = lists.do_sum(self.sprite_frames, function(f) return f.duration end)
    local frame_number = frame % total_frames
    local sprite_id = 1
    while frame_number >= 0 do
        if self.sprite_frames[sprite_id].duration < frame_number then
            return self.sprite_frames[sprite_id].sprite_name
        end
        frame_number = frame_number - self.sprite_frames[sprite_id].duration
        sprite_id = sprite_id + 1
    end
    -- TODO: double check this function
    return self.sprite_frames[#self.sprite_frames].sprite_name
end

--- Lerp between two points, at t = frame / duration
---@param o0 Point
---@param o1 Point
---@param frame integer
---@param duration integer
---@return Point
local function lerp_offsets(o0, o1, frame, duration)
    return o0 + (frame/duration) * (o1 - o0)
end

---@class PathAnimationPoint
---@field point Point
---@field duration integer

---@class PathAnimationInstance : AnimationInstance
---@field type "path" 
---@field current_point integer
---@field frame integer
---@field path_points PathAnimationPoint[]
---@field sprites SpriteFrameData
local PathAnimationInstance = {}
PathAnimationInstance.__index = PathAnimationInstance

function PathAnimationInstance:tick()
    self.frame = self.frame + 1
    if self.frame > self.path_points[self.current_point].duration then
        if self.current_point < #self.path_points - 1 then
            self.current_point = self.current_point + 1
            self.frame = 0
        else
            self.playing = false
        end
    end
end

---@param global_frame integer
---@return AnimationFrameName
function PathAnimationInstance:get_sprite_frame_name(global_frame)
    return self.sprites:get_at_frame(global_frame)
end

---@param _global_frame integer
---@return Point
function PathAnimationInstance:get_animation_offset(_global_frame)
    if #self.path_points == 1 then
        return self.path_points[1].point
    end

    local prev_point = self.path_points[self.current_point]
    local next_point = self.path_points[self.current_point+1]
    return lerp_offsets(prev_point.point, next_point.point, self.frame, prev_point.duration)
end

---@param _global_frame integer
---@return CardinalDirection?
function PathAnimationInstance:get_animation_facing(_global_frame)
    if #self.path_points == 1 then
        return nil
    end

    local prev_point = self.path_points[self.current_point]
    local next_point = self.path_points[self.current_point+1]
    if prev_point.point == nil or next_point.point == nil then
        return nil
    end

    local d = next_point.point - prev_point.point
    local angle = atan2(d.x, d.y)
    if abs(angle) <= 0.125 then
        return "right"
    elseif angle > 0.125 and angle < 0.375 then
        return "up"
    elseif angle < -0.125 and angle > 0.875 then
        return "down"
    else
        return "left"
    end
end

---@class DirectionalOffsetAnimationInstance : AnimationInstance
---@field type "offset"
---@field track number[] 
---@field frame integer 
---@field direction Angle
---@field sprites SpriteFrameData
local DirectionalOffsetAnimationInstance = {}
DirectionalOffsetAnimationInstance.__index = DirectionalOffsetAnimationInstance


function DirectionalOffsetAnimationInstance:tick()
    if self.frame >= #self.track then
        self.playing = false
    else
        self.frame = self.frame + 1
    end
end

---@param _global_frame integer
---@return AnimationFrameName
function DirectionalOffsetAnimationInstance:get_sprite_frame_name(_global_frame)
    return self.sprites:get_at_frame(self.frame)
end

---@param _global_frame integer
---@return Point
function DirectionalOffsetAnimationInstance:get_animation_offset(_global_frame)
    local track = self.track
    assert(self.frame <= #track)

    local direction = self.direction
    local offset = track[self.frame]
    return point.of_angle(direction, offset)
end

---@class GlobalAnimationInstance : AnimationInstance
---@field type "global"
---@field sprites SpriteFrameData
---@field duration integer
local GlobalAnimationInstance = {}
GlobalAnimationInstance.__index = GlobalAnimationInstance


function GlobalAnimationInstance:tick()

end

---@param global_frame integer
---@return AnimationFrameName
function GlobalAnimationInstance:get_sprite_frame_name(global_frame)
    return self.sprites:get_at_frame(global_frame)
end

---@param _global_frame integer
---@return Point
function GlobalAnimationInstance:get_animation_offset(_global_frame)
    return point.of(0, 0)
end

---@class AnimationFrameData
---@field frame AnimationFrameName
---@field facing CardinalDirection -- nillable
---@field offset Point

---@alias OffsetAnimationId
---| "BUMP"
---| "DODGE"
---| "HURT"
---| "DEATH"

---@class OffsetAnimationConfig
---@field sprites SpriteFrame[]
---@field track number[]

---@type { OffsetAnimationId: OffsetAnimationConfig }
local OFFSET_ANIMATION_DATA = {
    ["BUMP"] = {
        sprites = {
            {
                sprite_name = "idle_1",
                duration = 3
            },
            {
                sprite_name = "idle_2",
                duration = 5
            },
            {
                sprite_name = "idle_2",
                duration = 3
            }
        },
        track = { -- list of offsets
            0, 1, 1,3, 6, 7, 7, 7, 7, 6, 4, 2, 0
        }
    },
    ["DODGE"] = {
        sprites = {
            {
                sprite_name = "idle_1",
                duration = 60
            }
        },
        track = { -- list of offsets
            0, 2,4,6, 8, 8, 4, 2, 0
        }
    },
    ["HURT"] = {
        sprites = {
            {
                sprite_name = "idle_1",
                duration = 60
            }
        },
        track = { -- list of offsets
            0, 0, 0, 0, 6, 8, 8, 8, 6, 3, 0
        }
    },
    ["DEATH"] = {
        sprites = {
            {
                sprite_name = "death_1",
                duration = 60
            }
        },
        track = {
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        }
    }
}


---@class AnimationManager
---@field active_animations AnimationInstance[]
---@field global_frame integer
local AnimationManager = {}
AnimationManager.__index = AnimationManager

local animation = {}

---@return AnimationManager
function animation.animation_manager()
    return setmetatable({
        active_animations = {},
        global_frame = 0,
    }, AnimationManager)
end

function AnimationManager:tick()
    self.global_frame = self.global_frame + 1

    log.trace("Ticking "..#self.active_animations.." animations")
    for _, anim in ipairs(self.active_animations) do
        anim:tick()
    end
    local i = 1
    while i <= #self.active_animations do
        if not self.active_animations[i].playing then
            log.debug("Ending animation")
            self.active_animations[i].animated_object.playing = false
            deli(self.active_animations, i)
        else
            i = i + 1
        end
    end
end

-- animations such as "IDLE" which use shared frame counters
---@return AnimatedSpriteData
function AnimationManager:create_idle_animation()
    ---@type GlobalAnimationInstance
    local instance = {
        type = "global",
        duration = 120,
        sprites = sprite_frame_data.new({
            {
                sprite_name = "idle_1",
                duration = 60
            },
            {
                sprite_name = "idle_2",
                duration = 60
            }
        }),
        animated_object = { playing = true },
        playing = true
    }
    
    add(self.active_animations, instance)
    setmetatable(instance, GlobalAnimationInstance)

    return instance.animated_object
end

---comment
---@param animation_id OffsetAnimationId
---@param direction Angle
---@return AnimatedSpriteData
function AnimationManager:create_animation(animation_id, direction)
    local config = OFFSET_ANIMATION_DATA[animation_id]

    ---@type DirectionalOffsetAnimationInstance
    local animation_data = {
        type = "offset",
        frame = 1,
        direction = direction,
        playing = true,
        sprites = sprite_frame_data.new(config.sprites),
        track = config.track,
        animated_object = { playing = true }
    }

    add(self.active_animations, animation_data)
    setmetatable(animation_data, DirectionalOffsetAnimationInstance )

    return animation_data.animated_object
end

---
---@param path Point[]
---@param time_scale? integer
---@return AnimatedSpriteData
function AnimationManager:create_walk_animation(
    path,
    time_scale  -- default 1
)
    time_scale = time_scale or 1
    -- TODO: future
    -- - different terrain/unit speeds
    -- - faux elevation
    assert(#path > 0)
    local DURATION_PER_TILE = 8 * time_scale

    ---@type PathAnimationPoint[]
    local path_points = lists.map(
        function(p)
            return {
                point = p,
                duration = DURATION_PER_TILE
            }
        end
    )(path)
    path_points[#path].duration = nil

    ---@type PathAnimationInstance
    local instance = {
        type = "path",
        frame = 0,
        current_point = 1,
        path_points = path_points,
        sprites = sprite_frame_data.new({
            {
                sprite_name = "walk_1",
                duration = DURATION_PER_TILE
            },
            {
                sprite_name = "walk_2",
                duration = DURATION_PER_TILE
            }
        }),
        animated_object = { playing = true },
        playing = true
    }
    add(self.active_animations, instance)
    setmetatable(instance, PathAnimationInstance)

    return instance.animated_object
end

---comment
---@param anim AnimationInstance
---@return AnimationFrameData
function AnimationManager:get_frame_data(anim)
    local offset = anim:get_animation_offset(self.global_frame)
    local facing = anim.get_animation_facing and anim:get_animation_facing(self.global_frame) or nil
    local frame_name = anim:get_sprite_frame_name(self.global_frame)

    return {
        frame = frame_name,
        facing = facing,
        offset = offset
    }
end

function AnimationManager:generate_frame_data()
    for _, anim in ipairs(self.active_animations) do
        anim.animated_object.current_frame = self:get_frame_data(anim)
        anim.animated_object.playing = anim.playing
    end
end

return animation
