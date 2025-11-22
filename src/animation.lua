local ANIMATIONS = {}

local function lerp_animation_handler(animation_data)
    local d = animation_data.duration
    local t = animation_data.frame
    local x = animation_data.target_x
    local y = animation_data.target_y


    return t * (x) / d, t * (y) / d
end

local function directional_offsets_animation_handler(animation_data)
    local track = ANIMATIONS[animation_data.id].track
    assert(animation_data.frame <= #track)

    local direction = animation_data.direction
    local offset = track[animation_data.frame]
    return offset * cos(direction), offset * sin(direction)
end

ANIMATIONS = {
    ["WALK"] = {
        handler = lerp_animation_handler
    },
    ["BUMP"] = {
        duration = 10,
        track = { -- list of offsets
            0, 1, 4,12, 15, 16, 15, 12, 4, 1, 0
        },
        handler = directional_offsets_animation_handler
    },
    ["DODGE"] = {
        duration = 10,
        track = { -- list of offsets
            0, 1, 4,12, 15, 16, 15, 12, 4, 1, 0
        },
        handler = directional_offsets_animation_handler
    },
    ["HURT"] = {
        duration = 10,
        track = { -- list of offsets
            0, 0, 0, 0, 4, 6, 6, 6, 4, 2, 0
        },
        handler = directional_offsets_animation_handler
    },
    ["DEATH"] = {
        duration = 10,
        track = { -- list of offsets
            0, 1, 4,12, 12, 12, 12, 12, 12, 12, 12
        },
        handler = directional_offsets_animation_handler
    }
}

-- animation_data
-- frame
-- animation_id
-- direction

function create_animation(animation_id, direction)
    local animation_data = {
        id = animation_id,
        frame = 1,
        direction = direction,
        playing = true
    }

    setmetatable(animation_data, { __index = ANIMATIONS[animation_id] } )

    return animation_data
end

function create_walk_animation(target_x, target_y)
    -- TODO: make this grid aligned animation
    local animation_data = {
        id = "WALK",
        frame = 1,
        target_x = target_x,
        target_y = target_y,
        duration = 25,
        playing = true
    }

    setmetatable(animation_data, { __index = ANIMATIONS["WALK"] } )

    return animation_data
end

function update_animation(animation_data)
    if animation_data.frame >= animation_data.duration then
        animation_data.playing = false
    else
        animation_data.frame = animation_data.frame + 1
    end
end

function get_x_y_from_animation(animation_data)
    if animation_data == nil then return 0, 0 end

    return animation_data.handler(animation_data)
end