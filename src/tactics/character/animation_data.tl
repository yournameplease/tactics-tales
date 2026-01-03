local point = require("src/tactics/util/point")
local Point = point.Point
local maps = require("src/tactics/util/maps")
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
    "CHILD_BACK_HAND"
    "CHILD_HORIZONTAL"
    "CHILD_FRONT_HAND"
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
    anchors: { AnchorPointName: Point }
end

global record AnimationFrame
    sprite: integer
    anchors: { AnchorPointName: Point }
end

local type BaseAnimation = { AnimationFrameName: BaseAnimationFrame }

global type Animation = { AnimationFrameName: AnimationFrame }


local BASE_FRAMES <total>: { BaseAnimationName: BaseAnimation } = {
    BACK_HAND = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = point.of(9, 7),
                main_hand = point.of(1, 8),
                off_hand = point.of(14, 12),
                feet_center = point.of(7, 15)
            }
        },
        idle_2 = {
            sprite_offset = 1,
            anchors = {
                neck = point.of(10, 7),
                main_hand = point.of(1, 7),
                off_hand = point.of(14, 12),
                feet_center = point.of(7, 15)
            }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = point.of(9, 7),
                main_hand = point.of(1, 8),
                off_hand = point.of(14, 12),
                feet_center = point.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = point.of(9, 7),
                main_hand = point.of(1, 8),
                off_hand = point.of(14, 12),
                feet_center = point.of(7, 15)
            }
        },
    },
    HORIZONTAL = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = point.of(7, 7),
                main_hand = point.of(3, 12),
                off_hand = point.of(12, 12),
                feet_center = point.of(7, 15)
            }
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               neck = point.of(6, 7),
               main_hand = point.of(4, 11),
               off_hand = point.of(11, 12),
               feet_center = point.of(7, 15)
           }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = point.of(7, 7),
                main_hand = point.of(3, 12),
                off_hand = point.of(12, 12),
                feet_center = point.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = point.of(7, 7),
                main_hand = point.of(3, 12),
                off_hand = point.of(12, 12),
                feet_center = point.of(7, 15)
            }
        },
    },
    FRONT_HAND = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = point.of(6, 7),
                main_hand = point.of(13, 9),
                off_hand = point.of(3, 11),
                feet_center = point.of(7, 15)
            }
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               neck = point.of(7, 7),
               main_hand = point.of(14, 8),
               off_hand = point.of(4, 11),
               feet_center = point.of(7, 15)
           }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = point.of(6, 7),
                main_hand = point.of(13, 9),
                off_hand = point.of(3, 11),
                feet_center = point.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = point.of(6, 7),
                main_hand = point.of(13, 9),
                off_hand = point.of(3, 11),
                feet_center = point.of(7, 15)
            }
        },
    }
}

local CHILD_BASE_FRAMES <total>: { BaseAnimationName: BaseAnimation } = {
    BACK_HAND = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = point.of(9, 9),
                main_hand = point.of(1, 10),
                off_hand = point.of(14, 13),
                feet_center = point.of(7, 15)
            }
        },
        idle_2 = {
            sprite_offset = 1,
            anchors = {
                neck = point.of(10, 8),
                main_hand = point.of(1, 9),
                off_hand = point.of(14, 13),
                feet_center = point.of(7, 15)
            }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = point.of(9, 8),
                main_hand = point.of(1, 10),
                off_hand = point.of(14, 13),
                feet_center = point.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = point.of(9, 8),
                main_hand = point.of(1, 10),
                off_hand = point.of(14, 13),
                feet_center = point.of(7, 15)
            }
        },
    },
    HORIZONTAL = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = point.of(6, 8),
                main_hand = point.of(3, 12),
                off_hand = point.of(11, 13),
                feet_center = point.of(7, 15)
            }
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               neck = point.of(5, 8),
               main_hand = point.of(3, 11),
               off_hand = point.of(10, 13),
               feet_center = point.of(7, 15)
           }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = point.of(6, 8),
                main_hand = point.of(3, 12),
                off_hand = point.of(11, 13),
                feet_center = point.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = point.of(6, 8),
                main_hand = point.of(3, 12),
                off_hand = point.of(11, 13),
                feet_center = point.of(7, 15)
            }
        },
    },
    FRONT_HAND = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                neck = point.of(5, 8),
                main_hand = point.of(12, 10),
                off_hand = point.of(3, 12),
                feet_center = point.of(7, 15)
            }
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               neck = point.of(6, 8),
               main_hand = point.of(13, 9),
               off_hand = point.of(4, 12),
               feet_center = point.of(7, 15)
           }
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                neck = point.of(5, 8),
                main_hand = point.of(12, 10),
                off_hand = point.of(3, 12),
                feet_center = point.of(7, 15)
            }
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                neck = point.of(5, 8),
                main_hand = point.of(12, 10),
                off_hand = point.of(3, 12),
                feet_center = point.of(7, 15)
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

local function frames_from_base_frame_data(s: integer, base_frame: BaseAnimationName, base_frame_data: {BaseAnimationName: BaseAnimation}): Animation
    local base_animation: BaseAnimation = base_frame_data[base_frame]

    return maps.map(
        function (_: AnimationFrameName, f: BaseAnimationFrame): AnimationFrame
            return frame_from_base_frame(s, f)
        end
    )(base_animation)
end

local function frames_from_base_frame(s: integer, base_frame: BaseAnimationName): Animation
    return frames_from_base_frame_data(s, base_frame, BASE_FRAMES)
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
    CHILD_BACK_HAND = frames_from_base_frame_data(256, "BACK_HAND", CHILD_BASE_FRAMES),
    CHILD_HORIZONTAL = frames_from_base_frame_data(264, "HORIZONTAL", CHILD_BASE_FRAMES),
    CHILD_FRONT_HAND = frames_from_base_frame_data(272, "FRONT_HAND", CHILD_BASE_FRAMES),
}

return ANIMATION_DATA
