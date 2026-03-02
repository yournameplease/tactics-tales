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
            anchor = lib.point.of(14, 12)
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
        },
        appearance_overrides = {
            headwear = "helmet"
        }
    }
end


local ITEM_DATA = {
    dagger = lib.libs.weapon.melee( "Dagger", 96, 1, 90, 1 ),
    sword = lib.libs.weapon.melee( "Sword", 97, 2, 80, 1 ),
    axe = lib.libs.weapon.melee( "Axe", 98, 2, 70, 1, {
            lib.libs.weapon.effect.shieldsplitter()
        }
    ),
    spear = lib.libs.weapon.melee( "Spear", 99, 1, 90, 1, {
            lib.libs.weapon.effect.long_reach()
        }
    ),
    poleaxe = lib.libs.weapon.melee( "Poleaxe", 100, 2, 60, 1, {
            lib.libs.weapon.effect.long_reach(),
            lib.libs.weapon.effect.shieldsplitter()
        }
    ),
    club = lib.libs.weapon.melee( "Club", 101, 1, 80, 1),
    mace = lib.libs.weapon.melee( "Mace", 102, 2, 70, 1, {
            lib.libs.weapon.effect.armorkiller()
        }
    ),
    greatsword = lib.libs.weapon.two_handed( "Greatsword", 103, 3, 70, 2),
    bow = lib.libs.weapon.ranged( "Bow", 104, 2, 90, 2, 2, 2 ),
    shield = shield("Shield", 105, 1, 0, 10),
    armor = armor("Armor", 2, 1, -10),
    boulder = lib.libs.weapon.of(
        "Boulder",
        1,
        "TWO_HANDS",
        {
            sprite = 108,
            anchor = lib.point.of(7, 13),
        },
        {
            name = "Boulder",
            sprite = 108,
            damage = 3,
            accuracy = 60,
            targeting = {
                get_selection_tiles = function(origin, map)
                    local out = {}
                    local height = map.height
                    for y=origin.y+1,height-1 do
                        add(out, lib.point.of(origin.x, y))
                    end
            
                    return out
                end,
                get_targets_for_selection = function(origin, selection, map)
                    return map:get_units(function(u)
                        return u.tile.x == origin.x and u.tile.y > origin.y
                    end)
                end,
                is_target_valid = function(origin, selection, map)
                    return selection.x == origin.x and selection.y > origin.y
                end,
            },
            type = "RANGED",
            body_type = "BACK_HAND",
            effects = {},
        }
    ),
}

return ITEM_DATA
