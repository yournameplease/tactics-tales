local point = require("src/tactics/util/point")
local PointRecord = point.PointRecord
local maps = require("src/tactics/util/maps")
local animated_skeleton = require("src/tactics/animation/animated_skeleton")
local SkeletonNodeDefinition = animated_skeleton.SkeletonNodeDefinition
-- possible future work
-- z-ordering for hair, beards, shield, weapon, etc

local BODY_BACK_OFFSET = 4

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

global record BaseAnimationNode
    sprite_offset: integer
    anchors: { string: PointRecord }
    root: PointRecord 
end


local type BaseAnimationBody = { AnimationFrameName: BaseAnimationNode }

global type AnimationBodyByFrame = { AnimationFrameName: SkeletonNodeDefinition }

local BASE_FRAMES <total>: { BaseAnimationName: BaseAnimationBody } = {
    ["BACK_HAND"] = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                ["head"] = { x = 9, y = 8},
                ["main_hand"] = { x = 1, y = 8},
                ["off_hand"] = { x = 14, y = 12},
            },
            root = { x = 7, y = 15}
        },
        idle_2 = {
            sprite_offset = 1,
            anchors = {
                ["head"] = { x = 10, y = 8},
                ["main_hand"] = { x = 1, y = 7},
                ["off_hand"] = { x = 14, y = 12},
            },
            root = { x = 7, y = 15}
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                ["head"] = { x = 9, y = 8},
                ["main_hand"] = { x = 1, y = 8},
                ["off_hand"] = { x = 14, y = 12},
            },
            root = { x = 7, y = 15}
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                ["head"] = { x = 9, y = 8},
                ["main_hand"] = { x = 1, y = 8},
                ["off_hand"] = { x = 14, y = 12},
            },
            root = { x = 7, y = 15}
        },
    },
    ["HORIZONTAL"] = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                ["head"] = { x = 7, y = 8},
                ["main_hand"] = { x = 3, y = 12},
                ["off_hand"] = { x = 12, y = 12},
            },
            root = { x = 7, y = 15}
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               ["head"] = { x = 6, y = 8},
               ["main_hand"] = { x = 4, y = 11},
               ["off_hand"] = { x = 11, y = 12},
           },
           root = { x = 7, y = 15}
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                ["head"] = { x = 7, y = 8},
                ["main_hand"] = { x = 3, y = 12},
                ["off_hand"] = { x = 12, y = 12},
            },
            root = { x = 7, y = 15}
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                ["head"] = { x = 7, y = 8},
                ["main_hand"] = { x = 3, y = 12},
                ["off_hand"] = { x = 12, y = 12},
            },
            root = { x = 7, y = 15}
        },
    },
    ["FRONT_HAND"] = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                ["head"] = { x = 6, y = 8},
                ["main_hand"] = { x = 13, y = 9},
                ["off_hand"] = { x = 3, y = 11},
            },
            root = { x = 7, y = 15}
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               ["head"] = { x = 7, y = 8},
               ["main_hand"] = { x = 14, y = 8},
               ["off_hand"] = { x = 4, y = 11},
           },
           root = { x = 7, y = 15}
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                ["head"] = { x = 6, y = 8},
                ["main_hand"] = { x = 13, y = 9},
                ["off_hand"] = { x = 3, y = 11},
            },
            root = { x = 7, y = 15}
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                ["head"] = { x = 6, y = 8},
                ["main_hand"] = { x = 13, y = 9},
                ["off_hand"] = { x = 3, y = 11},
            },
            root = { x = 7, y = 15}
        },
    }
}

local CHILD_BASE_FRAMES <total>: { BaseAnimationName: BaseAnimationBody } = {
    ["BACK_HAND"] = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                ["head"] = { x = 9, y = 9},
                ["main_hand"] = { x = 1, y = 10},
                ["off_hand"] = { x = 14, y = 13},
            },
            root = { x = 7, y = 15}
        },
        idle_2 = {
            sprite_offset = 1,
            anchors = {
                ["head"] = { x = 10, y = 9},
                ["main_hand"] = { x = 1, y = 9},
                ["off_hand"] = { x = 14, y = 13},
            },
            root = { x = 7, y = 15}
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                ["head"] = { x = 9, y = 9},
                ["main_hand"] = { x = 1, y = 10},
                ["off_hand"] = { x = 14, y = 13},
            },
            root = { x = 7, y = 15}
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                ["head"] = { x = 9, y = 9},
                ["main_hand"] = { x = 1, y = 10},
                ["off_hand"] = { x = 14, y = 13},
            },
            root = { x = 7, y = 15}
        },
    },
    ["HORIZONTAL"] = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                ["head"] = { x = 6, y = 9},
                ["main_hand"] = { x = 3, y = 12},
                ["off_hand"] = { x = 11, y = 13},
            },
            root = { x = 7, y = 15}
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               ["head"] = { x = 5, y = 9},
               ["main_hand"] = { x = 3, y = 11},
               ["off_hand"] = { x = 10, y = 13},
           },
           root = { x = 7, y = 15}
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                ["head"] = { x = 6, y = 9},
                ["main_hand"] = { x = 3, y = 12},
                ["off_hand"] = { x = 11, y = 13},
            },
            root = { x = 7, y = 15}
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                ["head"] = { x = 6, y = 9},
                ["main_hand"] = { x = 3, y = 12},
                ["off_hand"] = { x = 11, y = 13},
            },
            root = { x = 7, y = 15}
        },
    },
    ["FRONT_HAND"] = {
        idle_1 = {
            sprite_offset = 0,
            anchors = {
                ["head"] = { x = 5, y = 9},
                ["main_hand"] = { x = 12, y = 10},
                ["off_hand"] = { x = 3, y = 12},
            },
            root = { x = 7, y = 15}
        },
        idle_2 = {
           sprite_offset = 1,
           anchors = {
               ["head"] = { x = 6, y = 9},
               ["main_hand"] = { x = 13, y = 9},
               ["off_hand"] = { x = 4, y = 12},
           },
           root = { x = 7, y = 15}
        },
        walk_1 = {
            sprite_offset = 2,
            anchors = {
                ["head"] = { x = 5, y = 9},
                ["main_hand"] = { x = 12, y = 10},
                ["off_hand"] = { x = 3, y = 12},
            },
            root = { x = 7, y = 15}
        },
        walk_2 = {
            sprite_offset = 3,
            anchors = {
                ["head"] = { x = 5, y = 9},
                ["main_hand"] = { x = 12, y = 10},
                ["off_hand"] = { x = 3, y = 12},
            },
            root = { x = 7, y = 15}
        },
    }
}

local function frame_from_base_frame(
    s: integer,
    base_frame: BaseAnimationNode
): SkeletonNodeDefinition
    local frame: SkeletonNodeDefinition = {
        sprite = s + base_frame.sprite_offset,
        sprite_back = s + base_frame.sprite_offset + BODY_BACK_OFFSET,
        anchors = base_frame.anchors,
        root = base_frame.root,
    }
    return frame
end

local function frames_from_base_frame_data(
    s: integer,
    base_frame: BaseAnimationName,
    base_frame_data: {BaseAnimationName: BaseAnimationBody}
): AnimationBodyByFrame
    local base_animation: BaseAnimationBody = base_frame_data[base_frame]

    return maps.map(
        function (_: AnimationFrameName, f: BaseAnimationNode): SkeletonNodeDefinition
            return frame_from_base_frame(s, f)
        end
    )(base_animation)
end

local function frames_from_base_frame(
    s: integer,
    base_frame: BaseAnimationName
): AnimationBodyByFrame
    return frames_from_base_frame_data(s, base_frame, BASE_FRAMES)
end

local ANIMATION_DATA: { AnimationName: AnimationBodyByFrame } = {
    ["DEFAULT_BACK_HAND"] = frames_from_base_frame(128, "BACK_HAND"),
    ["DEFAULT_HORIZONTAL"] = frames_from_base_frame(136, "HORIZONTAL"),
    ["DEFAULT_FRONT_HAND"] = frames_from_base_frame(144, "FRONT_HAND"),
    ["SLEEVELESS_BACK_HAND"] = frames_from_base_frame(160, "BACK_HAND"),
    ["SLEEVELESS_HORIZONTAL"] = frames_from_base_frame(168, "HORIZONTAL"),
    ["SLEEVELESS_FRONT_HAND"] = frames_from_base_frame(176, "FRONT_HAND"),
    ["SHIRTLESS_BACK_HAND"] = frames_from_base_frame(192, "BACK_HAND"),
    ["SHIRTLESS_HORIZONTAL"] = frames_from_base_frame(198, "HORIZONTAL"),
    ["SHIRTLESS_FRONT_HAND"] = frames_from_base_frame(206, "FRONT_HAND"),
    ["ROBED_BACK_HAND"] = frames_from_base_frame(224, "BACK_HAND"),
    ["ROBED_HORIZONTAL"] = frames_from_base_frame(232, "HORIZONTAL"),
    ["ROBED_FRONT_HAND"] = frames_from_base_frame(240, "FRONT_HAND"),
    ["CHILD_BACK_HAND"] = frames_from_base_frame_data(256, "BACK_HAND", CHILD_BASE_FRAMES),
    ["CHILD_HORIZONTAL"] = frames_from_base_frame_data(264, "HORIZONTAL", CHILD_BASE_FRAMES),
    ["CHILD_FRONT_HAND"] = frames_from_base_frame_data(272, "FRONT_HAND", CHILD_BASE_FRAMES),
}

return ANIMATION_DATA
