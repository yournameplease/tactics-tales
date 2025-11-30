require("src/types")
require("src/util")
require("src/character/animation_data")

global record AnimatedSpriteData
    current_frame: AnimationFrameData
    playing: boolean
end

local enum AnimationType
    "path"
    "offset"
    "global"
end

global interface AnimationInstance
    type: AnimationType
    playing: boolean
    tick: function(self)
    -- takes a the global frame as input
    get_sprite_frame_name: function(self, integer): AnimationFrameName
    get_animation_offset: function(self, integer): AnimationOffset

    animated_object: AnimatedSpriteData
end

local record SpriteFrame
    sprite_name: AnimationFrameName
    duration: integer
end

local record SpriteFrameData
    duration: integer
    sprite_frames: { SpriteFrame } 
end

function SpriteFrameData.new(sprite_frames: { SpriteFrame }): SpriteFrameData
    local duration = 0
    for _, v in ipairs(sprite_frames) do
        duration = duration + v.duration
    end
    
    return setmetatable({
        duration = duration,
        sprite_frames = sprite_frames
    }, {
        __index = SpriteFrameData
    })
end

function SpriteFrameData:get_at_frame(frame: integer): AnimationFrameName
    local frame_number = (frame % self.duration) // (self.duration // #self.sprite_frames)
    -- TODO: variable durations 
    return self.sprite_frames[frame_number].sprite_name
end

local function no_offset_calculator(_): AnimationOffset
    return { x = 0, y = 0}
end

local function lerp_offsets(o0: AnimationOffset, o1: AnimationOffset, frame: number, duration: number): AnimationOffset
    return {x = o0.x + frame * (o1.x - o0.x) / duration, y = o0.y + frame * (o1.y - o0.y) / duration }
end

local record PathAnimationPoint
    point: AnimationOffset
    duration: integer
end

local record PathAnimationInstance
    is AnimationInstance
    where self.type == "path" 
    current_point: integer
    frame: integer
    path_points: { PathAnimationPoint }
    sprites: SpriteFrameData
end

function PathAnimationInstance:tick()
    self.frame = self.frame + 1
    if self.frame > self.path_points[self.current_point].duration then
        self.current_point = self.current_point + 1
        self.frame = 0
    end
end

function PathAnimationInstance:get_sprite_frame_name(global_frame: integer): AnimationFrameName
    return self.sprites:get_at_frame(global_frame)
end

function PathAnimationInstance:get_animation_offset(_global_frame: integer): AnimationOffset
    if #self.path_points == 1 then
        return self.path_points[1].point
    end

    local prev_point = self.path_points[self.current_point]
    local next_point = self.path_points[self.current_point+1]
    return lerp_offsets(prev_point.point, next_point.point, self.frame, prev_point.duration)
end

local record DirectionalOffsetAnimationInstance
    is AnimationInstance
    where self.type == "offset"
    track: { number }
    frame: integer 
    direction: Angle
    sprites: SpriteFrameData
end

function DirectionalOffsetAnimationInstance:tick()
    if self.frame >= #self.track then
        self.playing = false
    else
        self.frame = self.frame + 1
    end
end

function DirectionalOffsetAnimationInstance:get_sprite_frame_name(_global_frame: integer): AnimationFrameName
    return self.sprites:get_at_frame(self.frame)
end

function DirectionalOffsetAnimationInstance:get_animation_offset(_global_frame: integer): AnimationOffset
    local track = self.track
    assert(self.frame <= #track)

    local direction = self.direction
    local offset = track[self.frame]
    return { x = offset * cos(direction), y = offset * sin(direction)}
end

global record GlobalAnimationInstance
    is AnimationInstance
    where self.type == "global"
    sprites: SpriteFrameData
    duration: integer
end

function GlobalAnimationInstance:tick()

end

function GlobalAnimationInstance:get_sprite_frame_name(global_frame: integer): AnimationFrameName
    return self.sprites:get_at_frame(global_frame)
end

function GlobalAnimationInstance:get_animation_offset(_global_frame: integer): AnimationOffset
    return { x = 0, y = 0 }
end

global record AnimationFrameData
    frame: AnimationFrameName
    offset: AnimationOffset
end

global enum OffsetAnimationId
    "BUMP"
    "DODGE"
    "HURT"
    "DEATH"
end

local record OffsetAnimationConfig
    sprites: { SpriteFrame }
    track: { number }
end

local OFFSET_ANIMATION_DATA<total>: { OffsetAnimationId: OffsetAnimationConfig } = {
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
                sprite_name = "idle_1",
                duration = 60
            }
        },
        track = {
            0, 1, 4,12, 12, 12, 12, 12, 12, 12, 12
        }
    }
}


global record AnimationManager
    active_animations: { AnimationInstance }
    global_frame: integer
end

function AnimationManager.new(): AnimationManager
    return setmetatable({
        active_animations = {},
        global_frame = 0
    }, { __index = AnimationManager })
end

function AnimationManager:tick()
    self.global_frame = self.global_frame + 1

    for _, animation in ipairs(self.active_animations) do
        animation:tick()
    end
end

-- animations such as "IDLE" which use shared frame counters
function AnimationManager:create_idle_animation(): AnimatedSpriteData
    local instance: GlobalAnimationInstance = {
        duration = 120,
        sprites = SpriteFrameData.new({
            {
                sprite_name = "idle_1",
                duration = 60
            },
            {
                sprite_name = "idle_2",
                duration = 60
            }
        }),
        animated_object = {}
    }

    setmetatable(instance, { __index = GlobalAnimationInstance } )

    return instance.animated_object
end

function AnimationManager:create_animation(animation_id: OffsetAnimationId, direction: Angle): AnimatedSpriteData
    local config = OFFSET_ANIMATION_DATA[animation_id]
    
    local animation_data: DirectionalOffsetAnimationInstance = {
        frame = 1,
        direction = direction,
        playing = true,
        sprites = SpriteFrameData.new(config.sprites),
        track = config.track,
        animated_object = {}
    }

    setmetatable(animation_data, { __index = DirectionalOffsetAnimationInstance } )

    return animation_data.animated_object
end

function AnimationManager:create_walk_animation(path: { AnimationOffset }): AnimatedSpriteData
    -- TODO: future
    -- - different terrain/unit speeds
    -- - faux elevation
    local DURATION_PER_TILE = 8

    local path_points: { PathAnimationPoint } = tmap(path, function(p: AnimationOffset): PathAnimationPoint
        return {
            point = p,
            duration = DURATION_PER_TILE
        }
    end)
    path_points[#path].duration = nil

    local instance: PathAnimationInstance = {
        frame = 0,
        current_point = 1,
        path_points = path_points,
        sprites = SpriteFrameData.new({
            {
                sprite_name = "idle_1",
                duration = 20
            },
            {
                sprite_name = "idle_2",
                duration = 20
            }
        }),
        animated_object = {}
    }

    setmetatable(instance, { __index = PathAnimationInstance })

    return instance.animated_object
end

function AnimationManager:get_frame_data(animation: AnimationInstance): AnimationFrameData
    local offset = animation:get_animation_offset(self.global_frame)
    local frame_name = animation:get_sprite_frame_name(self.global_frame)

    return {
        frame = frame_name,
        offset = offset
    }
end

function AnimationManager:generate_frame_data()
    for _, animation in ipairs(self.active_animations) do
        local frame_data = self:get_frame_data(animation)
        animation.animated_object.current_frame = frame_data
        animation.animated_object.playing = animation.playing
    end
end

return AnimationManager
