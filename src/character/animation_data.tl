require("src/util.lua")
-- possible future work
-- z-ordering for hair, beards, shield, weapon, etc

local BASE_FRAMES = {
    BACK_HAND = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = { x = 9, y = 7 },
                main_hand = { x = 1, y = 8 },
                off_hand = { x = 14, y = 12 },
                feet_center = { x = 7, y = 15 }
            }
        },
        idle_2 = {
            sprite_offset = 1,
            anchors = {
                neck = { x = 10, y = 7 },
                main_hand = { x = 1, y = 7 },
                off_hand = { x = 14, y = 12 },
                feet_center = { x = 7, y = 15 }
            }
        }
    },
    HORIZONTAL = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = { x = 7, y = 7 },
                main_hand = { x = 3, y = 12 },
                off_hand = { x = 12, y = 12 },
                feet_center = { x = 7, y = 15 }
            }
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               neck = { x = 6, y = 7 },
               main_hand = { x = 4, y = 11 },
               off_hand = { x = 11, y = 12 },
               feet_center = { x = 7, y = 15 }
           }
        },
    },
    FRONT_HAND = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = { x = 6, y = 7 },
                main_hand = { x = 13, y = 9 },
                off_hand = { x = 3, y = 11 },
                feet_center = { x = 7, y = 15 }
            }
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               neck = { x = 7, y = 7 },
               main_hand = { x = 14, y = 8 },
               off_hand = { x = 4, y = 11 },
               feet_center = { x = 7, y = 15 }
           }
        }
    }
}

local function frame_from_base_frame(s, base_frame)
    local frame = {
        sprite = s + base_frame.sprite_offset
    }
    setmetatable(frame, { __index = base_frame })
    return frame
end

local function frames_from_base_frame(s, base_frame)
    return tmap(BASE_FRAMES[base_frame], function (f) return frame_from_base_frame(s, f) end)
end

ANIMATION_DATA = {
    STANDARD_BACK_HAND = frames_from_base_frame(160, "BACK_HAND"),
    STANDARD_HORIZONTAL = frames_from_base_frame(168, "HORIZONTAL"),
    STANDARD_FRONT_HAND = frames_from_base_frame(176, "FRONT_HAND"),
}
