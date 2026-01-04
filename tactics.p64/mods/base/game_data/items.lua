
local point = {}

function point.of(x,y)
    return {x = x, y = y}
end

local effect = {}

function effect.long_reach()
    return {
        type = "long_reach"
    }
end

function effect.shieldsplitter()
    return {
        type = "shieldsplitter"
    }
end

function effect.armorkiller()
    return {
        type = "armorkiller"
    }
end

function effect.increase_defense(
    amount,
    defense_type
)
    return {
        type = "increase_defense",
        amount = amount,
        defense_type = defense_type
    }
end

function effect.increase_avoid(
    amount,
    avoid_type
)
    return {
        type = "increase_avoid",
        amount = amount,
        avoid_type = avoid_type
    }
end

local function shield(name, sprite_id, slots, defense, avoid)
    return {
        name = name,
        type = "SHIELD",
        slots = slots,
        equip_slot = "OFF_HAND",
        sprite_data = {
            sprite = sprite_id,
            anchor = point.of(14, 12)
        },

        equipment_effects = {
            effect.increase_defense(defense, "SHIELD"),
            effect.increase_avoid(avoid, "SHIELD")
        }        
    }
end

local function armor(name, slots, defense, avoid)
    return {
        name = name,
        type = "ARMOR",
        slots = slots,
        equip_slot = "BODY",

        equipment_effects = {
            effect.increase_defense(defense, "ARMOR"),
            effect.increase_avoid(avoid, "ARMOR")
        }        
    }
end

local default_weapon = {
    name = "Default Weapon",
    sprite = 104,
    hand_anchor = point.of(1,8), -- the top left position of the handle
    damage = 1,
    accuracy = 90,
    type = "MELEE",
    body_type = "BACK_HAND",
    min_range = 1,
    max_range = 1
}

local function weapon(
    name,
    slots,
    equip_slot,
    sprite_data,
    data
)
    setmetatable(data, { __index = default_weapon })
    return {
        name = name,
        type = "WEAPON",
        slots = slots,
        equip_slot = equip_slot,
        sprite_data = sprite_data,

        weapon_definition = data,
        equipment_effects = {}
    }
end

local function melee_weapon(
    name,
    sprite,
    damage,
    accuracy,
    slots,
    effects
)
    return weapon(
        name,
        slots,
        "MAIN_HAND",
        {
            sprite = sprite,
            anchor = point.of(1,8)
        },
        {
            name = name,
            damage = damage,
            accuracy = accuracy,
            effects = effects or {}
        }
    )
end

local function two_handed_weapon(
    name,
    sprite,
    damage,
    accuracy,
    slots,
    effects
)
    return weapon(
        name,
        slots,
        "TWO_HANDS",
        {
            sprite = sprite,
            anchor = point.of(3,12)
        },
        {
            name = name,
            sprite = sprite,
            damage = damage,
            accuracy = accuracy,
            body_type = "HORIZONTAL",
            effects = effects or {}
        }
    )
end

local function ranged_weapon(
    name,
    sprite,
    damage,
    accuracy,
    min_range,
    max_range,
    slots,
    effects
)
    return weapon(
        name,
        slots,
        "TWO_HANDS",
        {
            sprite = sprite,
            anchor = point.of(13,9) 
        },
        {
            name = name,
            sprite = sprite,
            damage = damage,
            accuracy = accuracy,
            min_range = min_range,
            max_range = max_range,
            type = "RANGED",
            body_type = "FRONT_HAND",
            effects = effects or {}
        }
    )
end


local ITEM_DATA = {
    dagger = melee_weapon( "Dagger", 96, 1, 90, 1 ),
    sword = melee_weapon( "Sword", 97, 2, 80, 1 ),
    axe = melee_weapon( "Axe", 98, 2, 70, 1, {
            effect.shieldsplitter()
        }
    ),
    spear = melee_weapon( "Spear", 99, 1, 90, 1, {
            effect.long_reach()
        }
    ),
    poleaxe = melee_weapon( "Poleaxe", 100, 2, 60, 1, {
            effect.long_reach(),
            effect.shieldsplitter()
        }
    ),
    club = melee_weapon( "Club", 101, 1, 80, 1),
    mace = melee_weapon( "Mace", 102, 2, 70, 1, {
            effect.armorkiller()
        }
    ),
    greatsword = two_handed_weapon( "Greatsword", 103, 3, 70, 2),
    bow = ranged_weapon( "Bow", 104, 2, 90, 2, 2, 2 ),
    shield = shield("Shield", 105, 1, 1, -10),
    armor = armor("Armor", 2, 1, -10)
}

return ITEM_DATA
