require("src/util")
local maps = require("src/util/maps")
-- possible future work
-- z-ordering for hair, beards, shield, weapon, etc

local enum BaseAnimationName
    "BACK_HAND"
    "FRONT_HAND"
    "HORIZONTAL"
end

global enum AnimationName
    "DEFAULT_BACK_HAND"
    "DEFAULT_HORIZONTAL"
    "DEFAULT_FRONT_HAND"
    "SLEEVELESS_BACK_HAND"
    "SLEEVELESS_HORIZONTAL"
    "SLEEVELESS_FRONT_HAND"
    "SHIRTLESS_BACK_HAND"
    "SHIRTLESS_HORIZONTAL"
    "SHIRTLESS_FRONT_HAND"
    "ROBED_BACK_HAND"
    "ROBED_HORIZONTAL"
    "ROBED_FRONT_HAND"
end

global enum AnimationFrameName
    "idle_1"
    "idle_2"
    "walk_1"
    "walk_2"
end

global enum AnchorPointName
    "neck"
    "main_hand"
    "off_hand"
    "feet_center"
end

global record BaseAnimationFrame
    sprite_offset: integer
    anchors: { AnchorPointName: AnimationAnchorPoint }
end

global record AnimationFrame
    sprite: integer
    anchors: { AnchorPointName: AnimationAnchorPoint }
end

local type BaseAnimation = { AnimationFrameName: BaseAnimationFrame }

global type Animation = { AnimationFrameName: AnimationFrame }


local BASE_FRAMES: { BaseAnimationName: BaseAnimation } = {
    BACK_HAND = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = AnimationAnchorPoint.of(9, 7),
                main_hand = AnimationAnchorPoint.of(1, 8),
                off_hand = AnimationAnchorPoint.of(14, 12),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
        idle_2 = {
            sprite_offset = 1,
            anchors = {
                neck = AnimationAnchorPoint.of(10, 7),
                main_hand = AnimationAnchorPoint.of(1, 7),
                off_hand = AnimationAnchorPoint.of(14, 12),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = AnimationAnchorPoint.of(9, 7),
                main_hand = AnimationAnchorPoint.of(1, 8),
                off_hand = AnimationAnchorPoint.of(14, 12),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = AnimationAnchorPoint.of(9, 7),
                main_hand = AnimationAnchorPoint.of(1, 8),
                off_hand = AnimationAnchorPoint.of(14, 12),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
    },
    HORIZONTAL = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = AnimationAnchorPoint.of(7, 7),
                main_hand = AnimationAnchorPoint.of(3, 12),
                off_hand = AnimationAnchorPoint.of(12, 12),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               neck = AnimationAnchorPoint.of(6, 7),
               main_hand = AnimationAnchorPoint.of(4, 11),
               off_hand = AnimationAnchorPoint.of(11, 12),
               feet_center = AnimationAnchorPoint.of(7, 15)
           }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = AnimationAnchorPoint.of(7, 7),
                main_hand = AnimationAnchorPoint.of(3, 12),
                off_hand = AnimationAnchorPoint.of(12, 12),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = AnimationAnchorPoint.of(7, 7),
                main_hand = AnimationAnchorPoint.of(3, 12),
                off_hand = AnimationAnchorPoint.of(12, 12),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
    },
    FRONT_HAND = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = AnimationAnchorPoint.of(6, 7),
                main_hand = AnimationAnchorPoint.of(13, 9),
                off_hand = AnimationAnchorPoint.of(3, 11),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               neck = AnimationAnchorPoint.of(7, 7),
               main_hand = AnimationAnchorPoint.of(14, 8),
               off_hand = AnimationAnchorPoint.of(4, 11),
               feet_center = AnimationAnchorPoint.of(7, 15)
           }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = AnimationAnchorPoint.of(6, 7),
                main_hand = AnimationAnchorPoint.of(13, 9),
                off_hand = AnimationAnchorPoint.of(3, 11),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = AnimationAnchorPoint.of(6, 7),
                main_hand = AnimationAnchorPoint.of(13, 9),
                off_hand = AnimationAnchorPoint.of(3, 11),
                feet_center = AnimationAnchorPoint.of(7, 15)
            }
        },
    }
}

local function frame_from_base_frame(s: integer, base_frame: BaseAnimationFrame ): AnimationFrame
    local frame = {
        sprite = s + base_frame.sprite_offset,
        anchors = base_frame.anchors
    }
    return frame
end

local function frames_from_base_frame(s: integer, base_frame: BaseAnimationName): Animation
    return maps.map(BASE_FRAMES[base_frame], function (f: BaseAnimationFrame): AnimationFrame return frame_from_base_frame(s, f) end)
end

local ANIMATION_DATA: { AnimationName: Animation } = {
    DEFAULT_BACK_HAND = frames_from_base_frame(128, "BACK_HAND"),
    DEFAULT_HORIZONTAL = frames_from_base_frame(136, "HORIZONTAL"),
    DEFAULT_FRONT_HAND = frames_from_base_frame(144, "FRONT_HAND"),
    SLEEVELESS_BACK_HAND = frames_from_base_frame(160, "BACK_HAND"),
    SLEEVELESS_HORIZONTAL = frames_from_base_frame(168, "HORIZONTAL"),
    SLEEVELESS_FRONT_HAND = frames_from_base_frame(176, "FRONT_HAND"),
    SHIRTLESS_BACK_HAND = frames_from_base_frame(192, "BACK_HAND"),
    SHIRTLESS_HORIZONTAL = frames_from_base_frame(198, "HORIZONTAL"),
    SHIRTLESS_FRONT_HAND = frames_from_base_frame(206, "FRONT_HAND"),
    ROBED_BACK_HAND = frames_from_base_frame(224, "BACK_HAND"),
    ROBED_HORIZONTAL = frames_from_base_frame(232, "HORIZONTAL"),
    ROBED_FRONT_HAND = frames_from_base_frame(240, "FRONT_HAND"),
}

return ANIMATION_DATA
