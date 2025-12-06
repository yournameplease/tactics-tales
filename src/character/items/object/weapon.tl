require("src/types")


global enum WeaponType
    "MELEE"
    "RANGED"
end

-- picks the relevant body sprite
global enum WeaponBodyType
    "BACK_HAND" -- standard 1h weapons
    "FRONT_HAND" -- bows, rapiers,
    "HORIZONTAL" -- heavy weapons
end

global enum WeaponProperty
    "armorkiller"
    "shieldsplitter"
    "long"
end

global type WeaponProperties = {
    WeaponProperty: boolean
}

global record Weapon
    name: string
    sprite: integer
    hand_anchor: AnimationAnchorPoint
    damage: integer
    accuracy: integer
    type: WeaponType
    body_type: WeaponBodyType
    min_range: integer
    max_range: integer
end

-- Equipment effects

global enum EquipmentEffectType
    "increase_defense"
    "increase_avoid"
    "long_reach"
    "shieldsplitter"
    "armorkiller"
end

global interface EquipmentEffect
    type: EquipmentEffectType
end

global enum DefenseType
    "ARMOR"
    "SHIELD"
    "OTHER"
    "TRUE"
end

global record IncreaseDefenseEffect
    is EquipmentEffect
    where self.type == "increase_defense"
    
    amount: integer
    defense_type: DefenseType
end

function IncreaseDefenseEffect.of(amount: integer, type: DefenseType): IncreaseDefenseEffect
    return {
        type = "increase_defense",
        amount = amount,
        defense_type = type
    }
end

global enum AvoidType
    "ARMOR"
    "SHIELD"
    "OTHER"
    "TRUE"
end

global record IncreaseAvoidEffect
    is EquipmentEffect
    where self.type == "increase_avoid"
    
    amount: integer
    avoid_type: AvoidType
end

function IncreaseAvoidEffect.of(amount: integer, type: AvoidType): IncreaseAvoidEffect
    return {
        type = "increase_avoid",
        amount = amount,
        avoid_type = type
    }
end

global record LongReachEffect
    is EquipmentEffect
    where self.type == "long_reach"
end

function LongReachEffect.of(): LongReachEffect
    return {
        type = "long_reach"
    }
end

global record ShieldsplitterEffect
    is EquipmentEffect
    where self.type == "shieldsplitter"
end

function ShieldsplitterEffect.of(): ShieldsplitterEffect
    return {
        type = "shieldsplitter"
    }
end

global record ArmorkillerEffect
    is EquipmentEffect
    where self.type == "armorkiller"
end

function ArmorkillerEffect.of(): ArmorkillerEffect
    return {
        type = "armorkiller"
    }
end
