---@brief
--- Calculates the outcome of combat between units.
--- It determines hit chance, damage, and the results of attacks
--- and counter-attacks based on unit stats and equipment.

local lists = require("src.tactics.util.lists")
local random = require("src.tactics.util.random")

---@class CombatStep
---@field attacker BattleUnit The attacking unit.
---@field defender BattleUnit The defending unit.
---@field hit_chance integer Hit percentage (0–100).
---@field hit_roll integer Random roll result (0–99).
---@field is_hit boolean Whether the attack connected.
---@field dmg integer Damage dealt if hit.
---@field destroy_shield boolean Whether the attack destroys the defender's shield.

---@class CombatResult
---@field steps CombatStep[]

---@class CombatPreviewResult
---@field steps CombatStep[]
---@field possible_kill boolean Can this attack kill the defender?
---@field possible_self_kill boolean Can the counterattack kill the attacker?
---@field possible_counterattack boolean Will there be a counterattack?
---@field expected_damage integer Guaranteed damage from the attacker if attack lands.
---@field expected_self_damage integer Guaranteed damage from the counterattack if it lands.

--- Internal snapshot of a weapon's combat-relevant data.
---@class AttackDouble
---@field damage integer
---@field accuracy integer
---@field targeting table Targeting interface for range validation.
---@field long_reach boolean True if the weapon cannot be countered by non-long-reach units.
---@field shieldsplitter boolean True if the weapon destroys shields on hit.
---@field ignored_defenses table<string, boolean> Defense types this weapon bypasses.
---@field ignored_avoids table<string, boolean> Avoid types this weapon bypasses.

--- Internal snapshot of a unit's combat-relevant data.
---@class CombatDouble
---@field id integer For debugging.
---@field tile table Point position on the map.
---@field hp_current integer Current HP (may be decremented during combat simulation).
---@field hp_max integer
---@field defense table<string, integer> Defense bonus per DefenseType key.
---@field avoid table<string, integer> Avoid bonus per AvoidType key.
---@field attacks AttackDouble[]
---@field unit BattleUnit The source unit.

local combat_calculator = {}

---@param weapon table Weapon record
---@return AttackDouble
local function build_attack_double(weapon)
    local double = {
        damage = weapon.damage,
        accuracy = weapon.accuracy,
        targeting = weapon.targeting,
        long_reach = false,
        shieldsplitter = false,
        ignored_defenses = {},
        ignored_avoids = {},
    }
    if weapon.effects then
        for _, eff in ipairs(weapon.effects) do
            if eff.type == "long_reach" then
                double.long_reach = true
            elseif eff.type == "shieldsplitter" then
                double.shieldsplitter = true
            elseif eff.type == "armorkiller" then
                double.ignored_defenses["ARMOR"] = true
                double.ignored_avoids["ARMOR"] = true
            elseif eff.type == "shieldkiller" then
                double.ignored_defenses["SHIELD"] = true
                double.ignored_avoids["SHIELD"] = true
            else
                unexpected(eff.type)
            end
        end
    end
    return double
end

---@param unit BattleUnit
---@return CombatDouble
local function build_combat_double(unit)
    local double = {
        id = unit.id,
        tile = unit.tile,
        hp_current = unit.hp_current,
        hp_max = unit.character.stats.hp_max,
        defense = {},
        avoid = {},
        -- TODO: multi-weapon combat not yet implemented; only attacks[1] is used
        attacks = lists.do_map(
            unit.character.inventory:get_equipped_weapons(),
            function(weapon) return build_attack_double(weapon) end
        ),
        unit = unit,
    }

    local equipped_items = unit.character.inventory:get_equipped_items()
    for _slot, item in pairs(equipped_items) do
        if item.equipment_effects then
            for _, eff in ipairs(item.equipment_effects) do
                if eff.type == "increase_defense" then
                    local def_eff = eff --[[@as IncreaseDefenseEffect]]
                    double.defense[def_eff.defense_type] = (double.defense[def_eff.defense_type] or 0) + def_eff.amount
                elseif eff.type == "increase_avoid" then
                    local avoid_eff = eff --[[@as IncreaseAvoidEffect]]
                    double.avoid[avoid_eff.avoid_type] = (double.avoid[avoid_eff.avoid_type] or 0) + avoid_eff.amount
                else
                    unexpected(eff.type)
                end
            end
        end
    end

    return double
end

---@param _attacker CombatDouble
---@param defender CombatDouble
---@param weapon AttackDouble
---@param map table BattleMap
---@return integer Hit chance clamped to 0–100.
local function get_hit_chance(_attacker, defender, weapon, map)
    local accuracy = weapon.accuracy

    local terrain = map:get_terrain(defender.tile)
    local terrain_avoid = terrain.dodge or 0

    local unit_avoid = 0
    for defense_type, amount in pairs(defender.avoid) do
        -- don't ignore penalties
        if (not weapon.ignored_avoids[defense_type]) or amount < 0 then
            unit_avoid = unit_avoid + (amount or 0)
        end
    end

    return math.max(0, math.min(accuracy - unit_avoid - terrain_avoid, 100))
end

---@param _attacker CombatDouble
---@param defender CombatDouble
---@param weapon AttackDouble
---@return integer Damage dealt, minimum 1 when weapon has positive damage.
local function get_damage(_attacker, defender, weapon)
    local atk = weapon.damage
    local def = 0

    for avoid_type, amount in pairs(defender.defense) do
        -- don't ignore penalties
        if (not weapon.ignored_defenses[avoid_type]) or amount < 0 then
            def = def + (amount or 0)
        end
    end

    local damage = math.max(0, math.min(atk - def, 999))
    if atk > 0 and damage == 0 then
        damage = 1
    end
    return damage
end

---@param attacker CombatDouble
---@param defender CombatDouble
---@param attack AttackDouble
---@param battle_map table BattleMap
---@return boolean
local function can_attack(attacker, defender, attack, battle_map)
    return attack.targeting.is_target_valid(attacker.tile, defender.tile, battle_map)
        and attacker.hp_current > 0
        and defender.hp_current > 0
end

--- Returns true if all of the unit's weapons have the long_reach effect.
---@param unit CombatDouble
---@return boolean
local function unit_is_long_reach(unit)
    for _, a in ipairs(unit.attacks) do
        if not a.long_reach then
            return false
        end
    end
    return true
end

---@param attacker CombatDouble The original attacker (who may be immune to counterattack).
---@param defender CombatDouble The defending unit attempting to counter.
---@param attack AttackDouble The defender's weapon for the counterattack.
---@param battle_map table BattleMap
---@return boolean
local function can_counter_attack(attacker, defender, attack, battle_map)
    if not attack then
        return false
    end
    local is_long_reach = unit_is_long_reach(attacker)
    log.trace("Checking counter attack", attacker.id, defender.id, is_long_reach, attack.long_reach)
    if is_long_reach and not attack.long_reach then
        return false
    end
    return can_attack(defender, attacker, attack, battle_map)
end

---@param attacker CombatDouble
---@param defender CombatDouble
---@param weapon AttackDouble
---@param map table BattleMap
---@return CombatStep?
local function get_combat_step(attacker, defender, weapon, map)
    if weapon ~= nil then
        local step = {
            attacker = attacker.unit,
            defender = defender.unit,
            hit_chance = get_hit_chance(attacker, defender, weapon, map),
            dmg = get_damage(attacker, defender, weapon),
            destroy_shield = weapon.shieldsplitter,
            hit_roll = random.rndi(100),
        }
        step.is_hit = step.hit_roll < step.hit_chance
        return step
    end
    return nil
end

--- Execute combat between two units, applying randomised hit rolls.
--- Returns 1–2 CombatSteps: the attacker's strike, and (if applicable) a counterattack.
---@param attacker_unit BattleUnit
---@param defender_unit BattleUnit
---@param battle_map table BattleMap
---@return CombatResult
function combat_calculator.compute_combat(attacker_unit, defender_unit, battle_map)
    ---@type CombatResult
    local result = { steps = {} }

    local attacker = build_combat_double(attacker_unit)
    local defender = build_combat_double(defender_unit)

    local attacker_attacks = attacker.attacks
    local defender_attacks = defender.attacks

    -- attack
    local step1 = get_combat_step(attacker, defender, attacker_attacks[1], battle_map)
    if step1 ~= nil then
        table.insert(result.steps, step1)
        if step1.is_hit then
            defender.hp_current = defender.hp_current - step1.dmg
        end
    end

    -- defender counterattack
    if can_counter_attack(attacker, defender, defender_attacks[1], battle_map) and defender.hp_current > 0 then
        local step2 = get_combat_step(defender, attacker, defender_attacks[1], battle_map)
        if step2 ~= nil then
            table.insert(result.steps, step2)
        end
    end

    return result
end

--- Preview combat for UI display. Does not apply damage to actual units.
--- The attacker's tile is overridden by attacker_tile to support previewing from a move target.
---@param attacker_unit BattleUnit
---@param defender_unit BattleUnit
---@param attacker_tile table Point — position the attacker would attack from.
---@param battle_map table BattleMap
---@return CombatPreviewResult
function combat_calculator.preview_combat(attacker_unit, defender_unit, attacker_tile, battle_map)
    ---@type CombatPreviewResult
    local result = {
        steps = {},
        possible_kill = false,
        possible_self_kill = false,
        possible_counterattack = false,
        expected_damage = 0,
        expected_self_damage = 0,
    }

    local attacker = build_combat_double(attacker_unit)
    attacker.tile = attacker_tile
    local defender = build_combat_double(defender_unit)

    local attacker_attacks = attacker.attacks
    local defender_attacks = defender.attacks

    -- attack
    local step1 = get_combat_step(attacker, defender, attacker_attacks[1], battle_map)
    if step1 ~= nil then
        table.insert(result.steps, step1)
        result.expected_damage = result.expected_damage + step1.dmg
    end

    -- defender counterattack
    if can_counter_attack(attacker, defender, defender_attacks[1], battle_map) then
        local step2 = get_combat_step(defender, attacker, defender_attacks[1], battle_map)
        if step2 ~= nil then
            result.possible_counterattack = true
            table.insert(result.steps, step2)
            result.expected_self_damage = result.expected_self_damage + step2.dmg
        end
    end

    result.possible_kill = result.expected_damage >= defender_unit.hp_current
    result.possible_self_kill = result.expected_self_damage >= attacker_unit.hp_current

    return result
end

return combat_calculator
