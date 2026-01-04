local point = require("src/tactics/util/point")
local Point = point.Point

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

local enum WeaponEffectType
    "long_reach"
    "shieldsplitter"
    "armorkiller"
end

local interface WeaponEffect
    type: WeaponEffectType
end

local record LongReachEffect
    is WeaponEffect
    where self.type == "long_reach"
end

local record ShieldsplitterEffect
    is WeaponEffect
    where self.type == "shieldsplitter"
end

local record ArmorkillerEffect
    is WeaponEffect
    where self.type == "armorkiller"
end

local record Weapon
    name: string
    sprite: integer
    hand_anchor: Point
    damage: integer
    accuracy: integer
    type: WeaponType
    body_type: WeaponBodyType
    min_range: integer
    max_range: integer

    effects: {WeaponEffect}
end

-- Equipment effects

local enum EquipmentEffectType
    "increase_defense"
    "increase_avoid"
end

local interface EquipmentEffect
    type: EquipmentEffectType
end

local enum DefenseType
    "ARMOR"
    "SHIELD"
    "OTHER"
    "TRUE"
end

local record IncreaseDefenseEffect
    is EquipmentEffect
    where self.type == "increase_defense"
    
    amount: integer
    defense_type: DefenseType
end

local enum AvoidType
    "ARMOR"
    "SHIELD"
    "OTHER"
    "TRUE"
end

local record IncreaseAvoidEffect
    is EquipmentEffect
    where self.type == "increase_avoid"
    
    amount: integer
    avoid_type: AvoidType
end

local weapon = {
    WeaponType = WeaponType,
    WeaponBodyType = WeaponBodyType,
    Weapon = Weapon,
    WeaponEffect = WeaponEffect,
    EquipmentEffect = EquipmentEffect,
    effect = {
        DefenseType = DefenseType,
        AvoidType = AvoidType,
        IncreaseDefenseEffect = IncreaseDefenseEffect,
        IncreaseAvoidEffect = IncreaseAvoidEffect,
        LongReachEffect = LongReachEffect,
        ShieldsplitterEffect = ShieldsplitterEffect,
        ArmorkillerEffect = ArmorkillerEffect        
    }
}

return weapon
