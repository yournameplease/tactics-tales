---@brief
--- Defines data structures for weapons and equipment effects.
--- Includes weapon targeting, special properties, and passive effects
--- granted by equipped items.

local point = require("src.tactics.util.point")
local Point = point.Point

global type BattleMap 
global type BattleUnit 

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
    "shieldkiller"
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

local record ShieldkillerEffect
    is WeaponEffect
    where self.type == "shieldkiller"
end

local interface Targeting
    get_selection_tiles: function(origin: Point, map: BattleMap): {Point}
    get_targets_for_selection: function(origin: Point, selection: Point, map: BattleMap): {BattleUnit}
    is_target_valid: function(origin: Point, selection: Point, map: BattleMap): boolean
end

local none_targeting: Targeting = {
    get_selection_tiles = function(_origin: Point, _map: BattleMap): {Point}
        return {}
    end,
    get_targets_for_selection = function(_origin: Point, _selection: Point, _map: BattleMap): {BattleUnit}
        return {}
    end,
    is_target_valid = function(_origin: Point, _selection: Point, _map: BattleMap): boolean
        return false
    end,
}


local record Weapon
    name: string
    sprite: integer
    hand_anchor: Point
    damage: integer
    accuracy: integer
    type: WeaponType
    body_type: WeaponBodyType
    targeting: Targeting

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


local effect_name <total>: {WeaponEffectType: string} = {
    ["long_reach"] = "Long Reach",
    ["shieldsplitter"] = "Shield-Splitter",
    ["armorkiller"] = "Armor-Killer",
    ["shieldkiller"] = "Shield-Killer",
}

local effect_description <total>: {WeaponEffectType: string} = {
    ["long_reach"] = "Cannot be countered unless defender also has Long Reach.",
    ["shieldsplitter"] = "Destroys shields.  (Not implemented)",
    ["armorkiller"] = "Ignores armor bonuses.",
    ["shieldkiller"] = "Ignores shield bonuses.",
}

local effect = {
    DefenseType = DefenseType,
    AvoidType = AvoidType,
    IncreaseDefenseEffect = IncreaseDefenseEffect,
    IncreaseAvoidEffect = IncreaseAvoidEffect,
    LongReachEffect = LongReachEffect,
    ShieldsplitterEffect = ShieldsplitterEffect,
    ArmorkillerEffect = ArmorkillerEffect,
    ShieldkillerEffect = ShieldkillerEffect,        
    effect_name = effect_name,
    effect_description = effect_description,
}

function effect.equipment_effect_description(eff: EquipmentEffect): string
    if eff is IncreaseDefenseEffect then
        return "Reduce damage taken by "..eff.amount..", to a minimum of 1."
    elseif eff is IncreaseAvoidEffect then
        return eff.amount.."% chance to dodge attacks." 
    end
end

local weapon = {
    WeaponType = WeaponType,
    WeaponBodyType = WeaponBodyType,
    Weapon = Weapon,
    WeaponEffect = WeaponEffect,
    EquipmentEffect = EquipmentEffect,
    targeting = {
        none = none_targeting,    
        Targeting = Targeting,
    },
    effect = effect,
}

return weapon
