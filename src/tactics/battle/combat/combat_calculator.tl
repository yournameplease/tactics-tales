local battle_unit = require("src/tactics/battle/tactics/battle_unit")
local BattleUnit = battle_unit.BattleUnit
require("src/tactics/battle/pathfinding")
require("src/tactics/debug")
local BattleMap = require("src/tactics/battle/battle_map").BattleMap
local point = require("src/tactics/util/point")
local Point = point.Point
local lists = require("src/tactics/util/lists")
local random = require("src/tactics/util/random")
local wpn = require("src/tactics/character/items/object/weapon")
local effect = wpn.effect

local record CombatResult
    record CombatStep
        attacker: BattleUnit
        defender: BattleUnit
        hit_chance: integer
        hit_roll: integer
        is_hit: boolean
        dmg: integer
        destroy_shield: boolean
    end

    steps: { CombatStep }
end


local record CombatPreviewResult
    record CombatPreviewStep
        attacker: BattleUnit
        defender: BattleUnit
        hit_chance: integer
        dmg: integer
        destroy_shield: boolean
    end
    steps: { CombatPreviewStep }
end

local combat_calculator = {
    CombatResult = CombatResult,
    CombatPreviewResult = CombatPreviewResult,
}

local record AttackDouble
    damage: integer
    accuracy: integer
    min_range: integer
    max_range: integer

    long_reach: boolean
    shieldsplitter: boolean

    ignored_defenses: {effect.DefenseType: boolean}
    ignored_avoids: {effect.AvoidType: boolean}
end

local record CombatDouble
    id: integer -- for debugging
    tile: Point
    hp_current: integer
    hp_max: integer
    defense: { effect.DefenseType: integer }
    avoid: { effect.AvoidType: integer }
    attacks: { AttackDouble }
    unit: BattleUnit
end

local function build_attack_double(weapon: wpn.Weapon): AttackDouble
    local double: AttackDouble = {
        damage = weapon.damage,
        accuracy = weapon.accuracy,
        min_range = weapon.min_range,
        max_range = weapon.max_range,
        long_reach = false,
        ignored_defenses = {},
        ignored_avoids = {},
    }
    for _, eff in ipairs(weapon.effects) do
        if eff is effect.LongReachEffect then
            double.long_reach = true
        elseif eff is effect.ShieldsplitterEffect then
            double.shieldsplitter = true
        elseif eff is effect.ArmorkillerEffect then
            double.ignored_defenses["ARMOR"] = true 
            double.ignored_avoids["ARMOR"] = true 
        else
            unexpected(eff.type)
        end
    end
    
    return double
end

local function build_combat_double(unit: BattleUnit): CombatDouble
    local double: CombatDouble = {
        id = unit.id,
        tile = unit.tile,
        hp_current = unit.hp_current,
        hp_max = unit.character.stats.hp_max,
        defense = { },
        avoid = { },
        attacks = lists.do_map(
            unit.character.inventory:get_equipped_weapons(),
            function(weapon: wpn.Weapon): AttackDouble
                return build_attack_double(weapon)
            end
        ),
        unit = unit
    }

    local equipped_items = unit.character.inventory:get_equipped_items()

    for _slot, item in pairs(equipped_items) do
        for _, eff in ipairs(item:get_equipment_effects()) do
            if eff is effect.IncreaseDefenseEffect then
                double.defense[eff.defense_type] = (double.defense[eff.defense_type] or 0) + eff.amount
            elseif eff is effect.IncreaseAvoidEffect then
                double.avoid[eff.avoid_type] = (double.avoid[eff.avoid_type] or 0) + eff.amount  
            else
                unexpected(eff.type)
            end
        end
    end
    
    return double
end

local function get_hit_chance(_attacker: CombatDouble, defender: CombatDouble, weapon: AttackDouble, map: BattleMap): integer
    local accuracy = weapon.accuracy

    local terrain = map:get_terrain(defender.tile)
    local terrain_avoid = (terrain.dodge or 0)

    local unit_avoid = 0

    for defense_type, amount in pairs(defender.avoid) do
        -- don't ignore penalties
        if (not weapon.ignored_avoids[defense_type]) or amount < 0 then
            unit_avoid = unit_avoid + amount or 0
        end
    end

    return pt.mid(0, accuracy - unit_avoid - terrain_avoid, 100)
end

local function get_damage(_attacker: CombatDouble, defender: CombatDouble, weapon: AttackDouble): integer
    local atk = weapon.damage
    local def = 0

    for avoid_type, amount in pairs(defender.defense) do
        -- don't ignore penalties
        if (not weapon.ignored_defenses[avoid_type]) or amount < 0 then
            def = def + amount or 0
        end
    end
    
    local damage = pt.mid(0, atk - def, 999)
    if atk > 0 and damage == 0 then
        damage = 1
    end
    return damage
end

local function is_in_combat_range(attacker: CombatDouble, defender: CombatDouble, attack: AttackDouble): boolean
    local dist = point.taxicab_distance(attacker.tile, defender.tile)

    LOG.debug("Checking combat range", attacker.id, attacker.tile, defender.id, defender.tile, attack.min_range, attack.max_range, dist)

    return dist >= attack.min_range and dist <= attack.max_range
end

local function can_attack(attacker: CombatDouble, defender: CombatDouble, attack: AttackDouble): boolean
    return is_in_combat_range(attacker, defender, attack)
            and attacker.hp_current > 0
            and defender.hp_current > 0
end

---@desc True if all attacks are long range
local function unit_is_long_reach(unit: CombatDouble): boolean
    for _,a in ipairs(unit.attacks) do
        if not a.long_reach then
            return false
        end
    end
    return true
end

local function can_counter_attack(attacker: CombatDouble, defender: CombatDouble, attack: AttackDouble): boolean
    local is_long_reach = unit_is_long_reach(attacker)
    LOG.debug("Checking counter attack", attacker.id, defender.id, is_long_reach, attack.long_reach)
    if is_long_reach and not attack.long_reach then
        return false
    end

    return can_attack(defender, attacker, attack)
end

local function get_combat_step(attacker: CombatDouble, defender: CombatDouble, weapon: AttackDouble, map: BattleMap): CombatResult.CombatStep
    if weapon ~= nil then
        local step: CombatResult.CombatStep = {
            attacker = attacker.unit,
            defender = defender.unit,
            hit_chance = get_hit_chance(attacker, defender, weapon, map),
            dmg = get_damage(attacker, defender, weapon),
            destroy_shield = weapon.shieldsplitter,
            hit_roll = random.rndi(100)
        }
        step.is_hit = step.hit_roll < step.hit_chance
        return step
    end
    return nil
end

function combat_calculator.compute_combat(attacker_unit: BattleUnit, defender_unit: BattleUnit, map: BattleMap): combat_calculator.CombatResult
    local result: combat_calculator.CombatResult = { steps = {} }

    local attacker = build_combat_double(attacker_unit)
    local defender = build_combat_double(defender_unit)

    local attacker_attacks = attacker.attacks
    local defender_attacks = defender.attacks
    
    -- attack
    local step1 = get_combat_step(attacker, defender, attacker_attacks[1], map)
    if step1 ~= nil then
        pt.add(result.steps, step1)
        if step1.is_hit then defender.hp_current = defender.hp_current - step1.dmg end
    end

    -- defender counterattack
    if can_counter_attack(attacker, defender, defender_attacks[1]) and defender.hp_current > 0 then -- Is there a good way to extract this?
        local step2 = get_combat_step(defender, attacker, defender_attacks[1], map)
        if step2 ~= nil then
            pt.add(result.steps, step2)
        end
    end

    return result
end

function combat_calculator.preview_combat(attacker_unit: BattleUnit, defender_unit: BattleUnit, attacker_tile: Point, map: BattleMap): CombatPreviewResult
    local result = { steps = {} }

    local attacker = build_combat_double(attacker_unit)
    attacker.tile = attacker_tile
    local defender = build_combat_double(defender_unit)

    local attacker_attacks = attacker.attacks
    local defender_attacks = defender.attacks
    
    -- attack
    local step1 = get_combat_step(attacker, defender, attacker_attacks[1], map)
    if step1 ~= nil then
        pt.add(result.steps, step1)
    end

    -- defender counterattack

    if can_counter_attack(attacker, defender, defender_attacks[1]) then
        local step2 = get_combat_step(defender, attacker, defender_attacks[1], map)
        if step2 ~= nil then
            pt.add(result.steps, step2)
        end
    end
    
    return result
end

return combat_calculator
