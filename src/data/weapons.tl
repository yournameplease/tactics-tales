require("src/types")
require("src/character/items/object/weapon")

-- potential additions
-- shields
-- dual wielding (use front hand sprite)

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

local function weapon(data: Weapon) : Weapon
    if data._range ~= nil then
        data.min_range = data._range
        data.max_range = data._range
    end
    setmetatable(data, { __index = default_weapon })
    return data
end

local function melee_weapon(
    name: string,
    sprite: integer,
    damage: integer,
    accuracy: integer,
    properties?: WeaponProperties
): Weapon
    return weapon({
        name = name,
        sprite = sprite,
        damage = damage,
        accuracy = accuracy,
        properties = properties,
        hand_anchor = AnimationAnchorPoint.of(1,8)
    })
end

local function two_handed_weapon(
    name: string,
    sprite: integer,
    damage: integer,
    accuracy: integer,
    properties?: WeaponProperties
): Weapon
    return weapon({
        name = name,
        sprite = sprite,
        damage = damage,
        accuracy = accuracy,
        properties = properties,
        body_type = "HORIZONTAL",
        hand_anchor = AnimationAnchorPoint.of(3,12)
    })
end

local function ranged_weapon(
    name: string,
    sprite: integer,
    damage: integer,
    accuracy: integer,
    min_range: integer,
    max_range: integer,
    properties?: WeaponProperties
): Weapon
    return weapon({
        name = name,
        sprite = sprite,
        damage = damage,
        accuracy = accuracy,
        properties = properties,
        hand_anchor = AnimationAnchorPoint.of(13,9), 
        min_range = min_range,
        max_range = max_range,
        type = "RANGED",
        body_type = "FRONT_HAND"
    })
end


global WEAPON_DATA: {string: Weapon} = {
    dagger = melee_weapon( "Dagger", 104, 1, 90 ),
    sword = melee_weapon( "Sword", 105, 2, 80 ),
    axe = melee_weapon( "Axe", 106, 2, 70, {
            shieldsplitter = true
        }
    ),
    spear = melee_weapon( "Spear", 107, 1, 90, {
            long = true
        }
    ),
    poleaxe = melee_weapon( "Poleaxe", 108, 2, 60, {
            long = true,
            shieldsplitter = true
        }
    ),
    club = melee_weapon( "Club", 109, 1, 80, {
            armorkiller = true
        }
    ),
    mace = melee_weapon( "Mace", 110, 2, 70, {
            armorkiller = true
        }
    ),
    greatsword = two_handed_weapon( "Greatsword", 111, 3, 70),
    bow = ranged_weapon( "Bow", 112, 2, 90, 2, 2 ),
}

return WEAPON_DATA
