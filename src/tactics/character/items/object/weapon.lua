---@brief
--- Defines data structures for weapons and equipment effects.
--- Includes weapon targeting, special properties, and passive effects
--- granted by equipped items.

---@alias WeaponType "MELEE"|"RANGED"

--- Determines which body sprite variant is shown when equipped.
---@alias WeaponBodyType "BACK_HAND"|"FRONT_HAND"|"HORIZONTAL"

---@alias WeaponEffectType "long_reach"|"shieldsplitter"|"armorkiller"|"shieldkiller"

---@class WeaponEffect
---@field type WeaponEffectType
local WeaponEffect = {}

---@class LongReachEffect : WeaponEffect
---@field type "long_reach"
local LongReachEffect = {}

---@class ShieldsplitterEffect : WeaponEffect
---@field type "shieldsplitter"
local ShieldsplitterEffect = {}

---@class ArmorkillerEffect : WeaponEffect
---@field type "armorkiller"
local ArmorkillerEffect = {}

---@class ShieldkillerEffect : WeaponEffect
---@field type "shieldkiller"
local ShieldkillerEffect = {}

---@class Targeting
---@field description? string Optional human-readable range description shown in the battle UI.
---@field get_selection_tiles fun(origin: Point, map: BattleMap, source_side: Side): Point[] Returns tiles the player can select as attack targets.
---@field get_targets_for_selection fun(origin: Point, selection: Point, map: BattleMap, source_side: Side): BattleUnit[] Returns units hit when a selection tile is chosen.
---@field is_target_valid fun(origin: Point, selection: Point, map: BattleMap, source_side: Side): boolean Returns whether the selected tile is a valid attack target.

---@type Targeting
local none_targeting = {
    get_selection_tiles = function(_origin, _map, _source_side)
        return {}
    end,
    get_targets_for_selection = function(_origin, _selection, _map, _source_side)
        return {}
    end,
    is_target_valid = function(_origin, _selection, _map, _source_side)
        return false
    end,
}

---@class Weapon
---@field name string
---@field sprite integer
---@field hand_anchor Point Sprite-space anchor point for the weapon hand.
---@field damage integer
---@field accuracy integer
---@field type WeaponType
---@field body_type WeaponBodyType Determines which body sprite variant is shown when equipped.
---@field targeting Targeting
---@field effects? WeaponEffect[] Combat properties granted by this weapon.
local Weapon = {}

-- Equipment effects

---@alias EquipmentEffectType "increase_defense"|"increase_avoid"

---@class EquipmentEffect
---@field type EquipmentEffectType

--- Defense category for equipment bonuses. "TRUE" is reserved and not yet implemented.
---@alias DefenseType "ARMOR"|"SHIELD"|"OTHER"|"TRUE"

---@class IncreaseDefenseEffect : EquipmentEffect
---@field type "increase_defense"
---@field amount integer Amount by which incoming damage is reduced.
---@field defense_type DefenseType

--- Avoid category for equipment bonuses. "TRUE" is reserved and not yet implemented.
---@alias AvoidType "ARMOR"|"SHIELD"|"OTHER"|"TRUE"

---@class IncreaseAvoidEffect : EquipmentEffect
---@field type "increase_avoid"
---@field amount integer Percentage chance to dodge attacks.
---@field avoid_type AvoidType
local IncreaseAvoidEffect = {}

---@type table<WeaponEffectType, string>
local effect_name = {
    ["long_reach"]     = "Long Reach",
    ["shieldsplitter"] = "Shield-Splitter",
    ["armorkiller"]    = "Armor-Killer",
    ["shieldkiller"]   = "Shield-Killer",
}

---@type table<WeaponEffectType, string>
local effect_description = {
    ["long_reach"]     = "Cannot be countered unless defender also has Long Reach.",
    ["shieldsplitter"] = "Destroys shields.  (Not implemented)",
    ["armorkiller"]    = "Ignores armor.",
    ["shieldkiller"]   = "Ignores shields.",
}

---@type table<WeaponEffectType, boolean>
local effect_should_display_name = {
    ["long_reach"]     = true,
    ["shieldsplitter"] = false,
    ["armorkiller"]    = false,
    ["shieldkiller"]   = false,
}

local effect = {
    effect_name                = effect_name,
    effect_description         = effect_description,
    effect_should_display_name = effect_should_display_name,
}

--- Return a player-facing description string for an equipment effect.
---@param eff EquipmentEffect
---@return string
function effect.equipment_effect_description(eff)
    if eff.type == "increase_defense" then
        ---@cast eff IncreaseDefenseEffect
        return "Reduce damage taken by " .. eff.amount .. ", to a minimum of 1."
    elseif eff.type == "increase_avoid" then
        ---@cast eff IncreaseAvoidEffect
        return eff.amount .. "% chance to dodge attacks."
    end
    return ""
end

local weapon = {
    Weapon       = Weapon,
    WeaponEffect = WeaponEffect,
    targeting    = {
        none = none_targeting,
    },
    effect       = effect,
}

return weapon
