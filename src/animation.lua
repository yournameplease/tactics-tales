
local AnimationManager = {}
local Animation = {}
local ANIMATIONS = {}

local function no_offset_calculator(_)
    return 0, 0
end

local function lerp_animation_offset_calculator(animation_data)
    local d = animation_data.duration
    local t = animation_data.frame
    local x = animation_data.target_x
    local y = animation_data.target_y


    return t * (x) / d, t * (y) / d
end

local function directional_offsets_offset_calculator(animation_data)
    local track = animation_data.track
    assert(animation_data.frame <= #track)

    local direction = animation_data.direction
    local offset = track[animation_data.frame]
    return offset * cos(direction), offset * sin(direction)
end

local ANIMATIONS = {
    ["IDLE"] = {
        repeating = true,
        sprites = {
            {
                sprite = "idle_1",
                duration = 60
            },
            {
                sprite = "idle_2",
                duration = 60
            }
        },
        offset_calculator = no_offset_calculator,
    },
    ["WALK"] = {
        sprites = {
            {
                sprite = "idle_1",
                duration = 10
            },
            {
                sprite = "idle_2",
                duration = 10
            }
        },
        offset_calculator = lerp_animation_offset_calculator
    },
    ["BUMP"] = {
        duration = 10,
        sprites = {
            {
                sprite = "idle_1",
                duration = 3
            },
            {
                sprite = "idle_2",
                duration = 5
            },
            {
                sprite = "idle_2",
                duration = 3
            }
        },
        track = { -- list of offsets
            0, 1, 4,12, 15, 16, 15, 12, 4, 1, 0
        },
        offset_calculator = directional_offsets_offset_calculator
    },
    ["DODGE"] = {
        duration = 10,
        sprites = {
            {
                sprite = "idle_1",
                duration = 60
            }
        },
        track = { -- list of offsets
            0, 1, 4,12, 15, 16, 15, 12, 4, 1, 0
        },
        offset_calculator = directional_offsets_offset_calculator
    },
    ["HURT"] = {
        duration = 10,
        sprites = {
            {
                sprite = "idle_1",
                duration = 60
            }
        },
        track = { -- list of offsets
            0, 0, 0, 0, 4, 6, 6, 6, 4, 2, 0
        },
        offset_calculator = directional_offsets_offset_calculator
    },
    ["DEATH"] = {
        duration = 10,
        sprites = {
            {
                sprite = "idle_1",
                duration = 60
            }
        },
        track = { -- list of offsets
            0, 1, 4,12, 12, 12, 12, 12, 12, 12, 12
        },
        offset_calculator = directional_offsets_offset_calculator
    }
}

-- animation_data
-- frame
-- animation_id
-- direction

function animation_metatable(animation_id)
    return {
        __index = function(t, k)
            if Animation[k] then return Animation[k] end

            return ANIMATIONS[animation_id][k]
        end
    }
end

function AnimationManager.create_animation(animation_id, direction)
    local animation_data = {
        rnd = rnd(1),
        id = animation_id,
        frame = 1,
        sprite_frame = 1,
        sprite = 1,
        direction = direction,
        playing = true
    }

    setmetatable(animation_data, animation_metatable(animation_id) )

    return animation_data
end

function AnimationManager.create_walk_animation(target_x, target_y)
    -- TODO: make this grid aligned animation
    local animation_data = {
        rnd = rnd(1),
        id = "WALK",
        frame = 1,
        sprite_frame = 1,
        sprite = 1,
        target_x = target_x,
        target_y = target_y,
        duration = 25,
        playing = true
    }

    setmetatable(animation_data, animation_metatable("WALK"))

    return animation_data
end

function Animation:update()
    if self.duration ~= nil and self.frame >= self.duration then
        self.playing = false
    else
        self.frame = self.frame + 1
        self.sprite_frame = self.sprite_frame + 1
        if (self.sprite_frame >
                self.sprites[1].duration) then
            self.sprite = (self.sprite % #self.sprites) + 1
            self.sprite_frame = 1
        end
    end
end

function Animation:get_x_y()
    return self.offset_calculator(self)
end

function Animation:get_anchors()
    return self.offset_calculator(self)
end

function Animation:get_frame_data()
    local x, y = self:get_x_y()
    return {
        sprite_id = self.sprites[self.sprite].sprite,
        x = x, y = y
    }
end

return AnimationManager