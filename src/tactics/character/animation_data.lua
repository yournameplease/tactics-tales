---@brief
--- Contains static data definitions for character animations.
--- Defines anchor points, sprite offsets, and frame data for different
--- body types and animation states.

local maps = require("src.tactics.util.maps")

-- possible future work
-- z-ordering for hair, beards, shield, weapon, etc

local BODY_BACK_OFFSET = 4

---@alias BaseAnimationName "BACK_HAND"|"FRONT_HAND"|"HORIZONTAL"|"COMMON"

---@alias AnimationName
---| "DEFAULT_BACK_HAND"
---| "DEFAULT_HORIZONTAL"
---| "DEFAULT_FRONT_HAND"
---| "DEFAULT_COMMON"
---| "SLEEVELESS_BACK_HAND"
---| "SLEEVELESS_HORIZONTAL"
---| "SLEEVELESS_FRONT_HAND"
---| "SLEEVELESS_COMMON"
---| "SHIRTLESS_BACK_HAND"
---| "SHIRTLESS_HORIZONTAL"
---| "SHIRTLESS_FRONT_HAND"
---| "SHIRTLESS_COMMON"
---| "ROBED_BACK_HAND"
---| "ROBED_HORIZONTAL"
---| "ROBED_FRONT_HAND"
---| "ROBED_COMMON"
---| "CHILD_BACK_HAND"
---| "CHILD_HORIZONTAL"
---| "CHILD_FRONT_HAND"
---| "CHILD_COMMON"

---@alias AnimationFrameName "idle_1"|"idle_2"|"walk_1"|"walk_2"|"death_1"

--- A single frame of a base (pre-skeleton) animation: sprite offset plus attachment anchors.
---@class BaseAnimationNode
---@field sprite_offset integer Offset added to the base sprite index for this frame.
---@field anchors table<string, PointRecord> Named attachment points (e.g. "head", "main_hand").
---@field root PointRecord Root anchor for positioning the node.

--- Full animation data for a single body animation name: one SkeletonNodeDefinition per frame.
---@alias AnimationBodyByFrame table<AnimationFrameName, SkeletonNodeDefinition>

--- Internal: one BaseAnimationNode per frame within a given base animation stance.
---@alias BaseAnimationBody table<AnimationFrameName, BaseAnimationNode>

---@type table<BaseAnimationName, BaseAnimationBody>
local BASE_FRAMES = {
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
    },
    ["COMMON"] = {
        death_1 = {
            sprite_offset = 0,
            anchors = {
                ["head"] = { x = 6, y = 10},
            },
            root = { x = 7, y = 15}
        },
    }
}

---@type table<BaseAnimationName, BaseAnimationBody>
local CHILD_BASE_FRAMES = {
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
    },
    ["COMMON"] = {
        death_1 = {
            sprite_offset = 0,
            anchors = {
                ["head"] = { x = 6, y = 9},
            },
            root = { x = 7, y = 15}
        },
    },
}

--- Build a SkeletonNodeDefinition from a base sprite index and a BaseAnimationNode.
---@param s integer Base sprite index for this body variant.
---@param base_frame BaseAnimationNode The frame data to expand.
---@return SkeletonNodeDefinition
local function frame_from_base_frame(s, base_frame)
    ---@type SkeletonNodeDefinition
    local frame = {
        sprite = s + base_frame.sprite_offset,
        sprite_back = s + base_frame.sprite_offset + BODY_BACK_OFFSET,
        anchors = base_frame.anchors,
        root = base_frame.root,
    }
    return frame
end

--- Build a full AnimationBodyByFrame from a base sprite index, stance name, and frame data table.
---@param s integer Base sprite index for this body variant.
---@param base_frame BaseAnimationName Which stance to expand.
---@param base_frame_data table<BaseAnimationName, BaseAnimationBody> The source frame data table.
---@return AnimationBodyByFrame
local function frames_from_base_frame_data(s, base_frame, base_frame_data)
    local base_animation = base_frame_data[base_frame]

    return maps.map(
        function (_, f)
            return frame_from_base_frame(s, f)
        end
    )(base_animation)
end

--- Build a full AnimationBodyByFrame from the standard BASE_FRAMES table.
---@param s integer Base sprite index for this body variant.
---@param base_frame BaseAnimationName Which stance to expand.
---@return AnimationBodyByFrame
local function frames_from_base_frame(s, base_frame)
    return frames_from_base_frame_data(s, base_frame, BASE_FRAMES)
end

---@type table<AnimationName, AnimationBodyByFrame>
local ANIMATION_DATA = {
    ["DEFAULT_BACK_HAND"] = frames_from_base_frame(128, "BACK_HAND"),
    ["DEFAULT_HORIZONTAL"] = frames_from_base_frame(136, "HORIZONTAL"),
    ["DEFAULT_FRONT_HAND"] = frames_from_base_frame(144, "FRONT_HAND"),
    ["DEFAULT_COMMON"] = frames_from_base_frame(152, "COMMON"),
    ["SLEEVELESS_BACK_HAND"] = frames_from_base_frame(160, "BACK_HAND"),
    ["SLEEVELESS_HORIZONTAL"] = frames_from_base_frame(168, "HORIZONTAL"),
    ["SLEEVELESS_FRONT_HAND"] = frames_from_base_frame(176, "FRONT_HAND"),
    ["SLEEVELESS_COMMON"] = frames_from_base_frame(184, "COMMON"),
    ["SHIRTLESS_BACK_HAND"] = frames_from_base_frame(192, "BACK_HAND"),
    ["SHIRTLESS_HORIZONTAL"] = frames_from_base_frame(198, "HORIZONTAL"),
    ["SHIRTLESS_FRONT_HAND"] = frames_from_base_frame(206, "FRONT_HAND"),
    ["SHIRTLESS_COMMON"] = frames_from_base_frame(216, "COMMON"),
    ["ROBED_BACK_HAND"] = frames_from_base_frame(224, "BACK_HAND"),
    ["ROBED_HORIZONTAL"] = frames_from_base_frame(232, "HORIZONTAL"),
    ["ROBED_FRONT_HAND"] = frames_from_base_frame(240, "FRONT_HAND"),
    ["ROBED_COMMON"] = frames_from_base_frame(248, "COMMON"),
    ["CHILD_BACK_HAND"] = frames_from_base_frame_data(256, "BACK_HAND", CHILD_BASE_FRAMES),
    ["CHILD_HORIZONTAL"] = frames_from_base_frame_data(264, "HORIZONTAL", CHILD_BASE_FRAMES),
    ["CHILD_FRONT_HAND"] = frames_from_base_frame_data(272, "FRONT_HAND", CHILD_BASE_FRAMES),
    ["CHILD_COMMON"] = frames_from_base_frame_data(280, "COMMON", CHILD_BASE_FRAMES),
}

return ANIMATION_DATA
