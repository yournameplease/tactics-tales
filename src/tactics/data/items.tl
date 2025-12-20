require("src/tactics/types")
require("src/tactics/character/items/object/weapon")
require("src/tactics/types/item_definition")
local wpn = require("src/tactics/character/items/object/weapon")
local effect = wpn.effect

-- potential additions
-- shields
-- dual wielding (use front hand sprite)


local function shield(name: string, sprite_id: integer, slots: integer, defense: integer, avoid: integer): ItemDefinition
    return {
        name = name,
        type = "SHIELD",
        slots = slots,
        equip_slot = "OFF_HAND",
        sprite_data = {
            sprite = sprite_id,
            anchor = AnimationAnchorPoint.of(14, 12)
        },

        equipment_effects = {
            effect.IncreaseDefenseEffect.of(defense, "SHIELD"),
            effect.IncreaseAvoidEffect.of(avoid, "SHIELD")
        }        
    }
end

local function armor(name: string, slots: integer, defense: integer, avoid: integer): ItemDefinition
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

local default_weapon: WeaponDefinition = {
    name = "Default Weapon",
    sprite = 104,
    hand_anchor = AnimationAnchorPoint.of(1,8), -- the top left position of the handle
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
    data: WeaponDefinition,
    effects?: {wpn.EquipmentEffect}
) : ItemDefinition
    setmetatable(data, { __index = default_weapon })
    return {
        name = name,
        type = "WEAPON",
        slots = slots,
        equip_slot = equip_slot,
        sprite_data = sprite_data,

        weapon_definition = data,
        equipment_effects = effects or {}
    }
end

local function melee_weapon(
    name: string,
    sprite: integer,
    damage: integer,
    accuracy: integer,
    slots: integer,
    effects?: { wpn.EquipmentEffect }
): ItemDefinition
    return weapon(
        name,
        slots,
        "MAIN_HAND",
        {
            sprite = sprite,
            anchor = AnimationAnchorPoint.of(1,8)
        },
        {
            name = name,
            damage = damage,
            accuracy = accuracy,
        },
        effects
    )
end

local function two_handed_weapon(
    name: string,
    sprite: integer,
    damage: integer,
    accuracy: integer,
    slots: integer,
    effects?: { wpn.EquipmentEffect }
): ItemDefinition
    return weapon(
        name,
        slots,
        "TWO_HANDS",
        {
            sprite = sprite,
            anchor = AnimationAnchorPoint.of(3,12)
        },
        {
            name = name,
            sprite = sprite,
            damage = damage,
            accuracy = accuracy,
            body_type = "HORIZONTAL"
        },
        effects
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
    effects?: { wpn.EquipmentEffect }
): ItemDefinition
    return weapon(
        name,
        slots,
        "TWO_HANDS",
        {
            sprite = sprite,
            anchor = AnimationAnchorPoint.of(13,9) 
        },
        {
            name = name,
            sprite = sprite,
            damage = damage,
            accuracy = accuracy,
            min_range = min_range,
            max_range = max_range,
            type = "RANGED",
            body_type = "FRONT_HAND"
        },
        effects
    )
end


global ITEM_DATA: {string: ItemDefinition} = {
    dagger = melee_weapon( "Dagger", 104, 1, 90, 1 ),
    sword = melee_weapon( "Sword", 105, 2, 80, 1 ),
    axe = melee_weapon( "Axe", 106, 2, 70, 1, {
            effect.ShieldsplitterEffect.of()
        }
    ),
    spear = melee_weapon( "Spear", 107, 1, 90, 1, {
            effect.LongReachEffect.of()
        }
    ),
    poleaxe = melee_weapon( "Poleaxe", 108, 2, 60, 1, {
            effect.LongReachEffect.of(),
            effect.ShieldsplitterEffect.of()
        }
    ),
    club = melee_weapon( "Club", 109, 1, 80, 1),
    mace = melee_weapon( "Mace", 110, 2, 70, 1, {
            effect.ArmorkillerEffect.of()
        }
    ),
    greatsword = two_handed_weapon( "Greatsword", 111, 3, 70, 2),
    bow = ranged_weapon( "Bow", 112, 2, 90, 2, 2, 2 ),
    shield = shield("Shield", 113, 1, 1, 20),
    armor = armor("Armor", 2, 1, 20)
}

return ITEM_DATA
