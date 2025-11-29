require("src/tactics/battle_unit")
require("src/tiles")
require("src/debug")

global record CombatCalculator
    tile_manager: TileManager
end

function CombatCalculator.new(tile_manager: TileManager): CombatCalculator
    local self = setmetatable({
        tile_manager = tile_manager
    }, { __index = CombatCalculator })
    return self
end

function CombatCalculator:get_hit_chance(attacker: BattleUnit, defender: BattleUnit): integer
    local accuracy = attacker.weapon.accuracy

    local terrain = self.tile_manager:get_terrain(defender.tile)
    local avoid = (terrain.dodge or 0)

    return mid(0, accuracy - avoid, 100)
end

function CombatCalculator:get_damage(attacker: BattleUnit, defender: BattleUnit): integer
    local atk = attacker.weapon.damage
    local def = defender.character.stats.def
    return mid(0, atk - def, 999)
end

function CombatCalculator:is_in_combat_range(attacker: BattleUnit, defender: BattleUnit): boolean
    local min_range = attacker.weapon.min_range
    local max_range = attacker.weapon.max_range
    local dist = taxicab_distance(attacker.tile, defender.tile)

    return dist >= min_range and dist <= max_range
end

function CombatCalculator:can_attack(attacker: BattleUnit, defender: BattleUnit): boolean
    LOG.debug(self:is_in_combat_range(attacker, defender), attacker:is_alive(), defender:is_alive())
    return self:is_in_combat_range(attacker, defender)
            and attacker:is_alive()
            and defender:is_alive()
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

function CombatCalculator:compute_combat(attacker: BattleUnit, defender: BattleUnit): CombatResult
    local result: CombatResult = { steps = {} }

    -- attack
    local step1: CombatStep = {
        attacker = attacker,
        defender = defender,
        hit_chance = self:get_hit_chance(attacker, defender),
        dmg = self:get_damage(attacker, defender),
        hit_roll = rndi(100)
    }
    step1.is_hit = step1.hit_roll < step1.hit_chance
    add(result.steps, step1)

    local virtual_hp = defender.hp_current
    if step1.is_hit then virtual_hp = virtual_hp - step1.dmg end

    -- defender counterattack
    if self:can_attack(defender, attacker) and virtual_hp > 0 then -- Is there a good way to extract this?
        local step2: CombatStep = {
            attacker = defender,
            defender = attacker,
            hit_chance = self:get_hit_chance(defender, attacker),
            dmg = self:get_damage(defender, attacker),
            hit_roll = rndi(100)
        }
        step2.is_hit = step2.hit_roll <= step2.hit_chance
        add(result.steps, step2)
    end

    return result
end

global record CombatPreviewStep
    attacker: BattleUnit
    defender: BattleUnit
    hit: integer
    dmg: integer
end

global record CombatPreviewResult
    steps: { CombatPreviewStep }
end

function CombatCalculator:preview_combat(attacker: BattleUnit, defender: BattleUnit): CombatPreviewResult
    local result = { steps = {} }

    -- attack
    local step1 = {
        attacker = attacker,
        defender = defender,
        hit = self:get_hit_chance(attacker, defender),
        dmg = self:get_damage(attacker, defender)
    }

    add(result.steps, step1)

    -- defender counterattack

    -- TODO: Lazy impl.  This won't work if ranges are more than fixed range
    -- may want some kind of "virtual unit" class
    if not (attacker.weapon.min_range > defender.weapon.max_range or attacker.weapon.max_range < defender.weapon.min_range) then
    --if can_attack(defender, attacker) then
        local step2 = {
            attacker = defender,
            defender = attacker,
            hit = self:get_hit_chance(defender, attacker),
            dmg = self:get_damage(defender, attacker)
        }
        add(result.steps, step2)
    end

    return result
end

return CombatCalculator
