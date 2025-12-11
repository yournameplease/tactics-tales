require("src/battle/tactics/battle_unit")
require("src/battle/pathfinding")
require("src/debug")
local List = require("src/util/list")



local record CombatCalculator
end

local record AttackDouble
    damage: integer
    accuracy: integer
    min_range: integer
    max_range: integer
end

local record CombatDouble
    tile: TilePoint
    hp_current: integer
    hp_max: integer
    defense: { DefenseType: integer }
    avoid: { AvoidType: integer }
    attacks: { AttackDouble }
    unit: BattleUnit
end

local function build_attack_double(weapon: Weapon, unit: BattleUnit): AttackDouble
    local double = {
        damage = weapon.damage,
        accuracy = weapon.accuracy,
        min_range = weapon.min_range,
        max_range = weapon.max_range,
    }
    return double
end

local function build_combat_double(unit: BattleUnit): CombatDouble
    local double: CombatDouble = {
        tile = unit.tile,
        hp_current = unit.hp_current,
        hp_max = unit.character.stats.hp_max,
        defense = { },
        avoid = { },
        attacks = List.do_map(
            unit.character.inventory:get_equipped_weapons(),
            function(weapon: Weapon): AttackDouble
                return build_attack_double(weapon, unit)
            end
        ),
        unit = unit
    }

    local equipped_items = unit.character.inventory:get_equipped_items()

    for _slot, item in pairs(equipped_items) do
        for _, effect in ipairs(item:get_equipment_effects()) do

        
            if effect is IncreaseDefenseEffect then
                double.defense[effect.defense_type] = (double.defense[effect.defense_type] or 0) + effect.amount
            end
    
            if effect is IncreaseAvoidEffect then
                double.avoid[effect.avoid_type] = (double.avoid[effect.avoid_type] or 0) + effect.amount  
            end
    
            if effect is LongReachEffect then

            end
    
            if effect is ShieldsplitterEffect then

            end
    
            if effect is ArmorkillerEffect then

            end
                   
        end
    end
    
    return double
end

local function get_hit_chance(attacker: CombatDouble, defender: CombatDouble, weapon: AttackDouble, battle_map: BattleMap): integer
    local accuracy = weapon.accuracy

    local terrain = battle_map:get_terrain(defender.tile)
    local terrain_avoid = (terrain.dodge or 0)

    local unit_avoid = 0

    for type, amount in pairs(defender.avoid) do
        unit_avoid = unit_avoid + amount or 0
    end

    return mid(0, accuracy - unit_avoid - terrain_avoid, 100)
end

local function get_damage(attacker: CombatDouble, defender: CombatDouble, weapon: AttackDouble): integer
    local atk = weapon.damage
    local def = 0

    for type, amount in pairs(defender.defense) do
        def = def + amount or 0
    end
    
    local damage = mid(0, atk - def, 999)
    if atk > 0 and damage == 0 then
        damage = 1
    end
    return damage
end

local function is_in_combat_range(attacker: CombatDouble, defender: CombatDouble, attack: AttackDouble): boolean
  
    local dist = taxicab_distance(attacker.tile, defender.tile)

    return dist >= attack.min_range and dist <= attack.max_range
end

local function can_attack(attacker: CombatDouble, defender: CombatDouble, attack: AttackDouble): boolean
    return is_in_combat_range(attacker, defender, attack)
            and attacker.hp_current > 0
            and defender.hp_current > 0
end

global record CombatStep
    attacker: BattleUnit
    defender: BattleUnit
    hit_chance: integer
    hit_roll: integer
    is_hit: boolean
    dmg: integer
end

global record CombatResult
    steps: { CombatStep }
end

local function get_combat_step(attacker: CombatDouble, defender: CombatDouble, weapon: AttackDouble, battle_map: BattleMap): CombatStep
    if weapon ~= nil then
        local step: CombatStep = {
            attacker = attacker.unit,
            defender = defender.unit,
            hit_chance = get_hit_chance(attacker, defender, weapon, battle_map),
            dmg = get_damage(attacker, defender, weapon),
            hit_roll = rndi(100)
        }
        step.is_hit = step.hit_roll < step.hit_chance
        return step
    end
    return nil
end

function CombatCalculator.compute_combat(attacker_unit: BattleUnit, defender_unit: BattleUnit, battle_map: BattleMap): CombatResult
    local result: CombatResult = { steps = {} }

    local attacker = build_combat_double(attacker_unit)
    local defender = build_combat_double(defender_unit)

    local attacker_attacks = attacker.attacks
    local defender_attacks = defender.attacks
    
    -- attack
    local step1 = get_combat_step(attacker, defender, attacker_attacks[1], battle_map)
    if step1 ~= nil then
        add(result.steps, step1)
        if step1.is_hit then defender.hp_current = defender.hp_current - step1.dmg end
    end


    -- defender counterattack
    if can_attack(defender, attacker, defender_attacks[1]) and defender.hp_current > 0 then -- Is there a good way to extract this?
        local step2 = get_combat_step(defender, attacker, defender_attacks[1], battle_map)
        if step2 ~= nil then
            add(result.steps, step2)
        end
    end

    return result
end

global record CombatPreviewStep
    attacker: BattleUnit
    defender: BattleUnit
    hit_chance: integer
    dmg: integer
end

global record CombatPreviewResult
    steps: { CombatPreviewStep }
end

function CombatCalculator.preview_combat(attacker_unit: BattleUnit, defender_unit: BattleUnit, attacker_tile: TilePoint, battle_map: BattleMap): CombatPreviewResult
    local result = { steps = {} }

    local attacker = build_combat_double(attacker_unit)
    attacker.tile = attacker_tile
    local defender = build_combat_double(defender_unit)

    local attacker_attacks = attacker.attacks
    local defender_attacks = defender.attacks
    
    -- attack
    local step1 = get_combat_step(attacker, defender, attacker_attacks[1], battle_map)
    if step1 ~= nil then
        add(result.steps, step1)
    end

    -- defender counterattack

    if can_attack(defender, attacker, defender_attacks[1]) then
        local step2 = get_combat_step(defender, attacker, defender_attacks[1], battle_map)
        if step2 ~= nil then
            add(result.steps, step2)
        end
    end
    
    return result
end

return CombatCalculator
