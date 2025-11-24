
local AnimationManager = {}
local Animation = {}
local ANIMATIONS = {}

local function no_offset_calculator(_)
    return 0, 0
end

local function lerp_x_y(x0, y0, x1, y1, t, d)
    return x0 + t * (x1 - x0) / d, y0 + t * (y1 - y0) / d
end

local function lerp_animation_offset_calculator(animation_data)
    local d = animation_data.duration
    local t = animation_data.frame
    local x = animation_data.target_x
    local y = animation_data.target_y

    return lerp_x_y(0, 0, x, y, t, d)
end

local function path_animation_offset_calculator(animation_data)
    if #animation_data.path_points == 1 then
        return animation_data.path_points[1].x, animation_data.path_points[1].y
    end

    local point_index = 1
    local duration_counter = animation_data.frame-1
    while (duration_counter >= 0) do
        local prev_point = animation_data.path_points[point_index]
        local next_point = animation_data.path_points[point_index+1]
        if duration_counter - prev_point.duration <= 0 then
            local t = duration_counter
            local d = prev_point.duration
            local x0 = prev_point.x
            local y0 = prev_point.y
            local x1 = next_point.x
            local y1 = next_point.y
            return lerp_x_y(x0, y0, x1, y1, t, d)
        end
        duration_counter = duration_counter - prev_point.duration
        point_index = point_index + 1
    end
    error("failed path animation")
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
        offset_calculator = path_animation_offset_calculator
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

function AnimationManager.create_walk_animation(path)
    -- TODO: future
    -- - different terrain/unit speeds
    -- - faux elevation
    local DURATION_PER_TILE = 8

    local path_points = tmap(path, function(p)
        return {
            x = p.x, y = p.y,
            duration = DURATION_PER_TILE
        }
    end)
    path_points[#path].duration = nil

    local animation_data = {
        id = "WALK",
        frame = 1,
        sprite_frame = 1,
        sprite = 1,
        duration = DURATION_PER_TILE * (#path - 1),
        path_points = path_points,
        playing = true
    }

    printh("hi anim")

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