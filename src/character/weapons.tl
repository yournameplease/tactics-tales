require("src/util/data_utils")

-- potential additions
-- shields
-- dual wielding (use front hand sprite)

local enum WeaponType
    "MELEE",
    "RANGED"
end

-- picks the relevant body sprite
local enum WeaponBodyType
    "BACK_HAND", -- standard 1h weapons
    "FRONT_HAND", -- bows, rapiers,
    "HORIZONTAL" -- heavy weapons
end

local default_weapon = {
    name = "Default Weapon",
    sprite = 104,
    hand_anchor = { x = 1, y = 8}, -- the top left position of the handle
    damage = 1,
    accuracy = 90,
    type = WEAPON_TYPES.MELEE,
    body_type = WEAPON_BODY_TYPES.BACK_HAND,
    range = 1,
    min_range = 1,
    max_range = 1,
    properties = {}
}

local function create_weapon(data)
    if data.range ~= nil then
        data.min_range = data.range
        data.max_range = data.range
    end
    setmetatable(data, { __index = default_weapon })
    return data
end

WEAPON_DATA = {
    dagger = create_weapon({
        name = "Dagger",
        sprite = 104,
        damage = 1,
        accuracy = 90
    }),
    sword = create_weapon({
        name = "Sword",
        sprite = 105,
        damage = 2,
        accuracy = 80
    }),
    axe = create_weapon({
        name = "Axe",
        sprite = 106,
        damage = 2,
        accuracy = 70,
        properties = {
            shieldsplitter = true
        }
    }),
    spear = create_weapon({
        name = "Spear",
        sprite = 107,
        damage = 1,
        accuracy = 90,
        properties = {
            long = true
        }
    }),
    poleaxe = create_weapon({
        name = "Poleaxe",
        sprite = 108,
        damage = 2,
        accuracy = 60,
        properties = {
            long = true,
            shieldsplitter = true
        }
    }),
    club = create_weapon({
        name = "Club",
        sprite = 109,
        damage = 1,
        accuracy = 80,
        properties = {
            armorkiller = true
        }
    }),
    mace = create_weapon({
        name = "Mace",
        sprite = 110,
        damage = 2,
        accuracy = 70,
        properties = {
            armorkiller = true
        }
    }),
    greatsword = create_weapon({
        name = "Greatsword",
        sprite = 111,
        hand_anchor = { x = 3, y = 12},
        damage = 3,
        accuracy = 70,
        body_type = WEAPON_BODY_TYPES.HORIZONTAL,
    }),
    bow = create_weapon({
        name = "Bow",
        sprite = 112,
        hand_anchor = { x = 13, y = 9},
        damage = 2,
        accuracy = 90,
        range = 2,
        type = WEAPON_TYPES.RANGED,
        body_type = WEAPON_BODY_TYPES.FRONT_HAND,
    }),
}
