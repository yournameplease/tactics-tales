local effect = {}

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


local ITEM_DATA = {
    dagger = lib.weapon.melee_weapon( "Dagger", 96, 1, 90, 1 ),
    sword = lib.weapon.melee_weapon( "Sword", 97, 2, 80, 1 ),
    axe = lib.weapon.melee_weapon( "Axe", 98, 2, 70, 1, {
            lib.weapon.effect.shieldsplitter()
        }
    ),
    spear = lib.weapon.melee_weapon( "Spear", 99, 1, 90, 1, {
            lib.weapon.effect.long_reach()
        }
    ),
    poleaxe = lib.weapon.melee_weapon( "Poleaxe", 100, 2, 60, 1, {
            lib.weapon.effect.long_reach(),
            lib.weapon.effect.shieldsplitter()
        }
    ),
    club = lib.weapon.melee_weapon( "Club", 101, 1, 80, 1),
    mace = lib.weapon.melee_weapon( "Mace", 102, 2, 70, 1, {
            lib.weapon.effect.armorkiller()
        }
    ),
    greatsword = lib.weapon.two_handed_weapon( "Greatsword", 103, 3, 70, 2),
    bow = lib.weapon.ranged_weapon( "Bow", 104, 2, 90, 2, 2, 2 ),
    shield = lib.weapon.shield("Shield", 105, 1, 1, -10),
    armor = lib.weapon.armor("Armor", 2, 1, -10)
}

return ITEM_DATA
