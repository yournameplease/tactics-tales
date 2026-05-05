local options = lib.libs.character.options

-- Default appearance template — all randomization options so character_generator
-- can build characters without requiring additional mods.
local DEFAULT = {
    movement = 5,
    hp_max = 4,
    item_loadout = {},

    head_options_m = options.list { "round", "strong_chin", "small_chin" },
    head_options_f = options.list { "narrow_chin", "round", "small_chin" },
    headwear_options = options.weighted {
        ["none"] = 8, ["wizard_hat"] = 1, ["hood"] = 1, ["bandana"] = 1
    },
    eyewear_options = options.weighted {
        ["none"] = 90, ["glasses_a"] = 2, ["glasses_b"] = 2, ["glasses_c"] = 2,
        ["eyepatch_l"] = 1, ["eyepatch_r"] = 1
    },
    body_options = options.weighted {
        ["default"] = 8, ["sleeveless"] = 1, ["robed"] = 1
    },
    gender_options = options.list { "male", "female" },
    skin_color_options = options.list { "a", "b", "c", "d" },
    hair_color_options = options.list {
        "brown", "dark_grey", "light_grey", "orange", "yellow",
        "dark_brown", "darker_grey", "dark_red", "dark_orange", "medium_grey", "peach"
    },
    beard_options = options.weighted {
        ["none"] = 8, ["beard"] = 1, ["handlebar"] = 1, ["walrus"] = 1,
        ["sideburns"] = 1, ["chin_beard"] = 1, ["goatee"] = 1,
        ["bushy_beard"] = 1, ["long_beard"] = 1
    },
    eye_options = options.weighted {
        ["a"] = 14, ["b"] = 1, ["c"] = 1, ["d"] = 1,
        ["e"] = 1, ["f"] = 1, ["g"] = 1, ["h"] = 1
    },
    hair_options_m = options.list {
        "bald", "pompadour", "short", "wavy", "afro_a",
        "buzz_a", "emo", "balding", "flat_top"
    },
    hair_options_f = options.list {
        "bald", "bob_bangs", "bob_a", "bob_b", "bob_c",
        "afro_b", "pigtails", "bun", "buzz_b"
    },

    parent_template = nil,
}

---@type ModCharactersModule
local characters = {
    default          = DEFAULT,
    test_fighter     = { parent_template = "default", hp_max = 10, movement = 3, item_loadout = {} },
    test_enemy       = { parent_template = "default", hp_max = 1, movement = 2, item_loadout = {} },
    test_armed_enemy = { parent_template = "default", hp_max = 1, movement = 2, item_loadout = { "test_sword" } },
}

return characters
