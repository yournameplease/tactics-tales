require("src/types")
require("src/util/data_utils")

-- potential additions
-- shields
-- dual wielding (use front hand sprite)

local enum WeaponType
    "MELEE"
    "RANGED"
end

-- picks the relevant body sprite
local enum WeaponBodyType
    "BACK_HAND" -- standard 1h weapons
    "FRONT_HAND" -- bows, rapiers,
    "HORIZONTAL" -- heavy weapons
end

local enum WeaponProperty
    "armorkiller"
    "shieldsplitter"
    "long"
end

global record Weapon
    name: string
    sprite: integer
    hand_anchor: AnimationAnchorPoint
    damage: integer
    accuracy: integer
    type: WeaponType
    body_type: WeaponBodyType
    _range: integer
    min_range: integer
    max_range: integer
    properties: { WeaponProperty: boolean } -- TODO: config table per property
end

local default_weapon: Weapon = {
    name = "Default Weapon",
    sprite = 104,
    hand_anchor = AnimationAnchorPoint.of(1,8), -- the top left position of the handle
    damage = 1,
    accuracy = 90,
    type = "MELEE",
    body_type = "BACK_HAND",
    _range = 1,
    min_range = 1,
    max_range = 1,
    properties = {}
}

local function create_weapon(data: Weapon) : Weapon
    if data._range ~= nil then
        data.min_range = data._range
        data.max_range = data._range
    end
    setmetatable(data, { __index = default_weapon })
    return data
end

global WEAPON_DATA: {string: Weapon} = {
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
        hand_anchor = AnimationAnchorPoint.of(3,12),
        damage = 3,
        accuracy = 70,
        body_type = "HORIZONTAL",
    }),
    bow = create_weapon({
        name = "Bow",
        sprite = 112,
        hand_anchor = AnimationAnchorPoint.of(13,9),
        damage = 2,
        accuracy = 90,
        _range = 2,
        type = "RANGED",
        body_type = "FRONT_HAND",
    }),
}

return WEAPON_DATA
