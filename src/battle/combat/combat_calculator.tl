require("src/battle/tactics/battle_unit")
require("src/battle/tile_manager")
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

function CombatCalculator:get_hit_chance(attacker: BattleUnit, defender: BattleUnit, weapon: Weapon): integer
    local accuracy = weapon.accuracy

    local terrain = self.tile_manager:get_terrain(defender.tile)
    local avoid = (terrain.dodge or 0)

    return mid(0, accuracy - avoid, 100)
end

function CombatCalculator:get_damage(attacker: BattleUnit, defender: BattleUnit, weapon: Weapon): integer
    local atk = weapon.damage
    local def = defender.character.stats.def
    return mid(0, atk - def, 999)
end

function CombatCalculator:is_in_combat_range(attacker: BattleUnit, defender: BattleUnit): boolean
    local min_range, max_range = attacker.character:get_weapon_range()
    
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

function CombatCalculator:get_combat_step(attacker: BattleUnit, defender: BattleUnit, weapon: Weapon): CombatStep
    if weapon ~= nil then
        local step: CombatStep = {
            attacker = attacker,
            defender = defender,
            hit_chance = self:get_hit_chance(attacker, defender, weapon),
            dmg = self:get_damage(attacker, defender, weapon),
            hit_roll = rndi(100)
        }
        step.is_hit = step.hit_roll < step.hit_chance
        return step
    end
    return nil
end

function CombatCalculator:compute_combat(attacker: BattleUnit, defender: BattleUnit): CombatResult
    local result: CombatResult = { steps = {} }

    local virtual_hp = defender.hp_current
    local attacker_weapons = attacker.character.inventory:get_equipped_weapons()
    local defender_weapons = defender.character.inventory:get_equipped_weapons()
    
    -- attack
    local step1 = self:get_combat_step(attacker, defender, attacker_weapons[1])
    if step1 ~= nil then
        add(result.steps, step1)
        if step1.is_hit then virtual_hp = virtual_hp - step1.dmg end
    end


    -- defender counterattack
    if self:can_attack(defender, attacker) and virtual_hp > 0 then -- Is there a good way to extract this?
        local step2 = self:get_combat_step(defender, attacker, defender_weapons[1])
        if step2 ~= nil then
            add(result.steps, step1)
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

function CombatCalculator:preview_combat(attacker: BattleUnit, defender: BattleUnit): CombatPreviewResult
    local result = { steps = {} }

    local attacker_weapons = attacker.character.inventory:get_equipped_weapons()
    local defender_weapons = defender.character.inventory:get_equipped_weapons()
    
    -- attack
    local step1 = self:get_combat_step(attacker, defender, attacker_weapons[1])
    if step1 ~= nil then
        add(result.steps, step1)
    end

    -- defender counterattack

    -- TODO: Lazy impl.  This won't work if ranges are more than fixed range
    -- may want some kind of "virtual unit" class
    local a_min_range, a_max_range = attacker.character:get_weapon_range()
    local d_min_range, d_max_range = defender.character:get_weapon_range()
    if not (a_min_range > d_max_range or a_max_range < d_min_range) then
    --if can_attack(defender, attacker) then
        local step2 = self:get_combat_step(defender, attacker, defender_weapons[1])
        if step2 ~= nil then
            add(result.steps, step1)
        end
    end
    
    return result
end

return CombatCalculator
