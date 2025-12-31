require("src/tactics/types")
require("src/tactics/character/items/object/weapon")
local item_definition = require("src/tactics/types/item_definition")
local wpn = require("src/tactics/character/items/object/weapon")
local effect = wpn.effect

-- potential additions
-- shields
-- dual wielding (use front hand sprite)


local function shield(name: string, sprite_id: integer, slots: integer, defense: integer, avoid: integer): item_definition.ItemDefinition
    return {
        name = name,
        type = "SHIELD",
        slots = slots,
        equip_slot = "OFF_HAND",
        sprite_data = {
            sprite = sprite_id,
            anchor = Point.of(14, 12)
        },

        equipment_effects = {
            effect.IncreaseDefenseEffect.of(defense, "SHIELD"),
            effect.IncreaseAvoidEffect.of(avoid, "SHIELD")
        }        
    }
end

local function armor(name: string, slots: integer, defense: integer, avoid: integer): item_definition.ItemDefinition
    return {
        name = name,
        type = "ARMOR",
        slots = slots,
        equip_slot = "BODY",

        equipment_effects = {
            effect.IncreaseDefenseEffect.of(defense, "ARMOR"),
            effect.IncreaseAvoidEffect.of(avoid, "ARMOR")
        }        
    }
end

local default_weapon: item_definition.WeaponDefinition = {
    name = "Default Weapon",
    sprite = 104,
    hand_anchor = Point.of(1,8), -- the top left position of the handle
    damage = 1,
    accuracy = 90,
    type = "MELEE",
    body_type = "BACK_HAND",
    min_range = 1,
    max_range = 1
}

local function weapon(
    name: string,
    slots: integer,
    equip_slot: EquipSlot,
    sprite_data: ItemSpriteData,
    data: item_definition.WeaponDefinition
) : item_definition.ItemDefinition
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
    name: string,
    sprite: integer,
    damage: integer,
    accuracy: integer,
    slots: integer,
    effects?: { wpn.WeaponEffect }
): item_definition.ItemDefinition
    return weapon(
        name,
        slots,
        "MAIN_HAND",
        {
            sprite = sprite,
            anchor = Point.of(1,8)
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
    name: string,
    sprite: integer,
    damage: integer,
    accuracy: integer,
    slots: integer,
    effects?: { wpn.WeaponEffect }
): item_definition.ItemDefinition
    return weapon(
        name,
        slots,
        "TWO_HANDS",
        {
            sprite = sprite,
            anchor = Point.of(3,12)
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
    name: string,
    sprite: integer,
    damage: integer,
    accuracy: integer,
    min_range: integer,
    max_range: integer,
    slots: integer,
    effects?: { wpn.WeaponEffect }
): item_definition.ItemDefinition
    return weapon(
        name,
        slots,
        "TWO_HANDS",
        {
            sprite = sprite,
            anchor = Point.of(13,9) 
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


local ITEM_DATA: {string: item_definition.ItemDefinition} = {
    dagger = melee_weapon( "Dagger", 96, 1, 90, 1 ),
    sword = melee_weapon( "Sword", 97, 2, 80, 1 ),
    axe = melee_weapon( "Axe", 98, 2, 70, 1, {
            effect.ShieldsplitterEffect.of()
        }
    ),
    spear = melee_weapon( "Spear", 99, 1, 90, 1, {
            effect.LongReachEffect.of()
        }
    ),
    poleaxe = melee_weapon( "Poleaxe", 100, 2, 60, 1, {
            effect.LongReachEffect.of(),
            effect.ShieldsplitterEffect.of()
        }
    ),
    club = melee_weapon( "Club", 101, 1, 80, 1),
    mace = melee_weapon( "Mace", 102, 2, 70, 1, {
            effect.ArmorkillerEffect.of()
        }
    ),
    greatsword = two_handed_weapon( "Greatsword", 103, 3, 70, 2),
    bow = ranged_weapon( "Bow", 104, 2, 90, 2, 2, 2 ),
    shield = shield("Shield", 105, 1, 1, 20),
    armor = armor("Armor", 2, 1, 20)
}

return ITEM_DATA
