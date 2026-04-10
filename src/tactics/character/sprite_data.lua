---@brief
--- A collection of static data for unit sprites.
--- Contains ids, names, sprites, and other information.
--- Has ordered lists for use in character customization menus.

--- Abstract base for all named sprite data entries.
---@class NamedSpriteData
---@field name string Display name shown in menus.
local NamedSpriteData = {}

--- A named colour drawn from the Picotron palette.
---@class NamedColor : NamedSpriteData
---@field name string
---@field color integer Picotron palette index.
local NamedColor = {}

--- A named sprite with optional front/back variants.
---@class SpriteData : NamedSpriteData
---@field name string
---@field sprite integer? Sprite index for the front-facing frame.
---@field back_sprite integer? Sprite index for the back-facing frame.
local SpriteData = {}

--- Skin colour entry; stores two palette indices for highlight and shadow.
---@class SkinColorData : NamedSpriteData
---@field name string
---@field colors integer[] Two-element array: [highlight_color, shadow_color].
local SkinColorData = {}

--- Body class entry; maps a body style to its sprite ID prefix.
---@class BodyClassData : NamedSpriteData
---@field name string
---@field id_prefix string Prefix used to look up animation data keys.
local BodyClassData = {}

--- Headwear entry; controls which facial features are drawn beneath it.
---@class HeadwearSpriteData : NamedSpriteData
---@field name string Currently unused; present for readability.
---@field draw_hair boolean Whether hair is drawn when this headwear is equipped.
---@field draw_beard boolean Whether beard is drawn when this headwear is equipped.
---@field draw_eyewear boolean Whether eyewear is drawn when this headwear is equipped.
---@field sprite integer? Front-facing sprite index.
---@field back_sprite integer? Back-facing sprite index.
local HeadwearSpriteData = {}

-- Names from https://picotron.fandom.com/wiki/Palette
---@type table<string, NamedColor>
local COLOR_NAMES = {
    black = {
        name = "Black",
        color = 0,
    },
    dark_blue = {
        name = "Dark Blue",
        color = 1,
    },
    dark_purple = {
        name = "Dark Purple",
        color = 2,
    },
    dark_green = {
        name = "Dark Green",
        color = 3,
    },
    brown = {
        name = "Brown",
        color = 4,
    },
    dark_grey = {
        name = "Dark Grey",
        color = 5,
    },
    light_grey = {
        name = "Light Grey",
        color = 6,
    },
    white = {
        name = "White",
        color = 7,
    },
    red = {
        name = "Red",
        color = 8,
    },
    orange = {
        name = "Orange",
        color = 9,
    },
    yellow = {
        name = "Yellow",
        color = 10,
    },
    green = {
        name = "Green",
        color = 11,
    },
    blue = {
        name = "Blue",
        color = 12,
    },
    lavender = {
        name = "Lavender",
        color = 13,
    },
    pink = {
        name = "Pink",
        color = 14,
    },
    light_peach = {
        name = "Light Peach",
        color = 15,
    },
    true_blue = {
        name = "True Blue",
        color = 16,
    },
    teal = {
        name = "Teal",
        color = 17,
    },
    purple = {
        name = "Purple",
        color = 18,
    },
    dark_teal = {
        name = "Dark Teal",
        color = 19,
    },
    dark_brown = {
        name = "Dark Brown",
        color = 20,
    },
    darker_grey = {
        name = "Darker Grey",
        color = 21,
    },
    medium_grey = {
        name = "Medium Grey",
        color = 22,
    },
    light_pink = {
        name = "Light Pink",
        color = 23,
    },
    dark_red = {
        name = "Dark Red",
        color = 24,
    },
    dark_orange = {
        name = "Dark Orange",
        color = 25,
    },
    lime_green = {
        name = "Lime Green",
        color = 26,
    },
    medium_green = {
        name = "Medium Green",
        color = 27,
    },
    light_blue = {
        name = "Light Blue",
        color = 28,
    },
    mauve = {
        name = "Mauve",
        color = 29,
    },
    magenta = {
        name = "Magenta",
        color = 30,
    },
    peach = {
        name = "Peach",
        color = 31,
    },
}

---@type table<string, SpriteData>
local HEAD = {
    round = {
        name = "Round",
        sprite = 0,
    },
    strong_chin = {
        name = "Strong",
        sprite = 1,
    },
    -- bony_chin = {
    --     name = "Bony",
    --     sprite = 2,
    -- },
    -- blocky_chin = {
    --     name = "Blocky",
    --     sprite = 3,
    -- },
    narrow_chin = {
        name = "Narrow",
        sprite = 4,
    },
    -- pointed_chin = {
    --     name = "Pointed",
    --     sprite = 5,
    -- },
    -- chubby_chin = {
    --     name = "Chubby",
    --     sprite = 6,
    -- },
    small_chin = {
        name = "Small",
        sprite = 7,
    },
}

---@type table<string, SpriteData>
local HAIR = {
    bald = {
        name = "Bald",
        sprite = nil,
        back_sprite = nil,
    },
    pompadour = {
        name = "Pompadour",
        sprite = 16,
        back_sprite = 32,
    },
    short = {
        name = "Short",
        sprite = 17,
        back_sprite = 33,
    },
    wavy = {
        name = "Wavy",
        sprite = 18,
        back_sprite = 33,
    },
    afro_a = {
        name = "Afro A",
        sprite = 19,
        back_sprite = 35,
    },
    buzz_a = {
        name = "Buzz A",
        sprite = 20,
        back_sprite = 36,
    },
    emo = {
        name = "Emo",
        sprite = 21,
        back_sprite = 33,
    },
    balding = {
        name = "Balding",
        sprite = 22,
        back_sprite = 38,
    },
    flat_top = {
        name = "Flat Top",
        sprite = 23,
        back_sprite = 39,
    },
    bob_bangs = {
        name = "Bob Bangs",
        sprite = 24,
        back_sprite = 40,
    },
    bob_a = {
        name = "Bob A",
        sprite = 25,
        back_sprite = 41,
    },
    bob_b = {
        name = "Bob B",
        sprite = 26,
        back_sprite = 42,
    },
    bob_c = {
        name = "Bob C",
        sprite = 27,
        back_sprite = 43,
    },
    afro_b = {
        name = "Afro B",
        sprite = 28,
        back_sprite = 44,
    },
    pigtails = {
        name = "Pigtails",
        sprite = 29,
        back_sprite = 45,
    },
    bun = {
        name = "Bun",
        sprite = 30,
        back_sprite = 46,
    },
    buzz_b = {
        name = "Buzz B",
        sprite = 31,
        back_sprite = 47,
    },
}

---@type table<string, SpriteData>
local FACIAL_HAIR = {
    none = {
        name = "None",
        sprite = nil,
    },
    beard = {
        name = "Beard",
        sprite = 48,
    },
    handlebar = {
        name = "Handlebar",
        sprite = 49,
    },
    walrus = {
        name = "Walrus",
        sprite = 50,
    },
    sideburns = {
        name = "Sideburns",
        sprite = 51,
    },
    chin_beard = {
        name = "Chin Beard",
        sprite = 52,
    },
    goatee = {
        name = "Goatee",
        sprite = 53,
    },
    bushy_beard = {
        name = "Bushy Beard",
        sprite = 54,
    },
    long_beard = {
        name = "Long Beard",
        sprite = 55,
    },
}

---@type table<string, SpriteData>
local EYES = {
    a = {
        name = "A",
        sprite = 8,
    },
    b = {
        name = "B",
        sprite = 9,
    },
    c = {
        name = "C",
        sprite = 10,
    },
    d = {
        name = "D",
        sprite = 11,
    },
    e = {
        name = "E",
        sprite = 12,
    },
    f = {
        name = "F",
        sprite = 13,
    },
    g = {
        name = "G",
        sprite = 14,
    },
    h = {
        name = "H",
        sprite = 15,
    },
}

---@type table<string, SpriteData>
local EYEWEAR = {
    none = {
        name = "None",
        sprite = nil,
    },
    glasses_a = {
        name = "Glasses A",
        sprite = 80,
    },
    glasses_b = {
        name = "Glasses B",
        sprite = 81,
    },
    glasses_c = {
        name = "Glasses C",
        sprite = 82,
    },
    monacle_l = {
        name = "Monacle L",
        sprite = 83,
    },
    monacle_r = {
        name = "Monacle R",
        sprite = 84,
    },
    mask = {
        name = "Mask",
        sprite = 85,
        back_sprite = 93,
    },
    eyepatch_l = {
        name = "Eyepatch L",
        sprite = 86,
        back_sprite = 94,
    },
    eyepatch_r = {
        name = "Eyepatch R",
        sprite = 87,
        back_sprite = 95,
    },
}

---@type table<string, SkinColorData>
local SKIN_COLOR = {
    a = {
        name = "A",
        colors = {15, 31},
    },
    b = {
        name = "B",
        colors = {31, 4},
    },
    c = {
        name = "C",
        colors = {4, 20},
    },
    d = {
        name = "D",
        colors = {20, 21},
    },
}

---@type table<string, BodyClassData>
local BODY_CLASS = {
    default = {
        name = "Shirt",
        id_prefix = "DEFAULT",
    },
    sleeveless = {
        name = "Sleeveless",
        id_prefix = "SLEEVELESS",
    },
    shirtless = {
        name = "Shirtless",
        id_prefix = "SHIRTLESS",
    },
    robed = {
        name = "Robed",
        id_prefix = "ROBED",
    },
    child = {
        name = "Child",
        id_prefix = "CHILD",
    },
}

---@type table<string, HeadwearSpriteData>
local HEADWEAR = {
    none = {
        name = "None",
        draw_hair = true,
        draw_beard = true,
        draw_eyewear = true,
        sprite = nil,
    },
    hood = {
        name = 'Hood',
        draw_hair = false,
        draw_beard = false,
        draw_eyewear = true,
        sprite = 65,
        back_sprite = 73,
    },
    cultist_hood = {
        name = 'Covered Hood',
        draw_hair = false,
        draw_beard = false,
        draw_eyewear = false,
        sprite = 70,
        back_sprite = 78,
    },
    wizard_hat = {
        name = 'Wizard Hat',
        draw_hair = false,
        draw_beard = true,
        draw_eyewear = true,
        sprite = 64,
        back_sprite = 72,
    },
    hooded_wizard_hat = {
        name = 'Hooded Wizard Hat',
        draw_hair = false,
        draw_beard = false,
        draw_eyewear = false,
        sprite = 71,
        back_sprite = 79,
    },
    fancy_hat = {
        name = 'Fancy Hat',
        draw_hair = false,
        draw_beard = true,
        draw_eyewear = true,
        sprite = 69,
        back_sprite = 77,
    },
    animal_mask = {
        name = 'Animal Mask',
        draw_hair = true,
        draw_beard = true,
        draw_eyewear = false,
        sprite = 68,
    },
    bandana = {
        name = 'Bandana',
        draw_hair = true,
        draw_beard = false,
        draw_eyewear = true,
        sprite = 66,
        back_sprite = 74,
    },
    outlaw_hat = {
        name = 'Outlaw Hat',
        draw_hair = false,
        draw_beard = false,
        draw_eyewear = true,
        sprite = 67,
        back_sprite = 75,
    },
    crown = {
        name = 'Crown',
        draw_hair = false,
        draw_beard = true,
        draw_eyewear = true,
        sprite = 113,
        back_sprite = 121,
    },
    helmet = {
        name = 'Helmet',
        draw_hair = false,
        draw_beard = false,
        draw_eyewear = false,
        sprite = 112,
        back_sprite = 120,
    },
}

--- Ordered options, for character selection

local HEAD_OPTIONS = {
    "round",
    "strong_chin",
    -- "bony_chin",
    -- "blocky_chin",
    "narrow_chin",
    -- "pointed_chin",
    -- "chubby_chin",
    "small_chin",
}

local HAIR_OPTIONS = {
    "bald",
    "pompadour",
    "short",
    "wavy",
    "afro_a",
    "buzz_a",
    "emo",
    "balding",
    "flat_top",
    "bob_bangs",
    "bob_a",
    "bob_b",
    "bob_c",
    "afro_b",
    "pigtails",
    "bun",
    "buzz_b",
}

local HAIR_COLOR_OPTIONS = {
    "brown",
    "dark_grey",
    "light_grey",
    "orange",
    "yellow",
    "dark_brown",
    "darker_grey",
    "dark_red",
    "dark_orange",
    "medium_grey",
    "peach",
    "white",
}

local FACIAL_HAIR_OPTIONS = {
    "none",
    "beard",
    "handlebar",
    "walrus",
    "sideburns",
    "chin_beard",
    "goatee",
    "bushy_beard",
    "long_beard",
}

local EYES_OPTIONS = {
    "a",
    "b",
    "c",
    "d",
    "e",
    "f",
    "g",
    "h",
}

local EYEWEAR_OPTIONS = {
    "none",
    "glasses_a",
    "glasses_b",
    "glasses_c",
    "monacle_l",
    "monacle_r",
    "mask",
    "eyepatch_l",
    "eyepatch_r",
}

local SKIN_COLOR_OPTIONS = {
    "a",
    "b",
    "c",
    "d",
}

local BODY_CLASS_OPTIONS = {
    "default",
    "sleeveless",
    "shirtless",
    "robed",
    "child",
}

local HEADWEAR_OPTIONS = {
    "none",
    "hood",
    "cultist_hood",
    "wizard_hat",
    "hooded_wizard_hat",
    "fancy_hat",
    "animal_mask",
    "bandana",
    "outlaw_hat",
    "crown",
}

local customization_options = {
    HEAD = HEAD_OPTIONS,
    HAIR = HAIR_OPTIONS,
    HAIR_COLOR = HAIR_COLOR_OPTIONS,
    FACIAL_HAIR = FACIAL_HAIR_OPTIONS,
    EYES = EYES_OPTIONS,
    EYEWEAR = EYEWEAR_OPTIONS,
    SKIN_COLOR = SKIN_COLOR_OPTIONS,
    BODY_CLASS = BODY_CLASS_OPTIONS,
    HEADWEAR = HEADWEAR_OPTIONS,
}

return {
    NamedSpriteData = NamedSpriteData,
    NamedColor = NamedColor,
    SpriteData = SpriteData,
    SkinColorData = SkinColorData,
    HeadwearSpriteData = HeadwearSpriteData,

    COLOR_NAMES = COLOR_NAMES,

    HEAD = HEAD,
    HAIR = HAIR,
    FACIAL_HAIR = FACIAL_HAIR,
    EYES = EYES,
    EYEWEAR = EYEWEAR,
    SKIN_COLOR = SKIN_COLOR,
    BODY_CLASS = BODY_CLASS,
    HEADWEAR = HEADWEAR,

    customization_options = customization_options,
}
