local Calculator = {}

function Calculator.get_hit_chance(attacker, defender)
    local accuracy = attacker.weapon.accuracy

    local terrain = TILE_MANAGER.get_terrain(defender.x, defender.y)
    local avoid = (terrain.dodge or 0)

    return mid(0, accuracy - avoid, 100)
end

function Calculator.get_damage(attacker, defender)
    local atk = attacker.weapon.damage
    local def = defender.stats.def
    return mid(0, atk - def, 999)
end

local function can_attack(attacker, defender)
    LOG.debug(is_in_combat_range(attacker, defender), attacker:is_alive(), defender:is_alive())
    return is_in_combat_range(attacker, defender)
            and attacker:is_alive()
            and defender:is_alive()
end

function Calculator.compute_combat(attacker, defender)
    local result = { steps = {} }

    -- attack
    local step1 = {
        attacker = attacker,
        defender = defender,
        hit = Calculator.get_hit_chance(attacker, defender),
        dmg = Calculator.get_damage(attacker, defender),
        roll = rnd(100)
    }

    step1.is_hit = step1.roll <= step1.hit
    add(result.steps, step1)

    local virtual_hp = defender.hp_current
    if step1.is_hit then virtual_hp = virtual_hp - step1.dmg end

    -- defender counterattack
    if can_attack(defender, attacker) and virtual_hp > 0 then -- Is there a good way to extract this?
        local step2 = {
            attacker = defender,
            defender = attacker,
            hit = Calculator.get_hit_chance(defender, attacker),
            dmg = Calculator.get_damage(defender, attacker),
            roll = rnd(100)
        }
        step2.is_hit = step2.roll <= step2.hit
        add(result.steps, step2)
    end

    return result
end

function Calculator.preview_combat(attacker, defender)
    local result = { steps = {} }

    -- attack
    local step1 = {
        attacker = attacker,
        defender = defender,
        hit = Calculator.get_hit_chance(attacker, defender),
        dmg = Calculator.get_damage(attacker, defender)
    }

    add(result.steps, step1)

    -- defender counterattack

    -- TODO: Lazy impl.  This won't work if ranges are more than fixed range
    -- may want some kind of "virtual unit" class
    if not (attacker.min_range > defender.max_range and attacker.max_range < defender.min_range) then
    --if can_attack(defender, attacker) then
        local step2 = {
            attacker = defender,
            defender = attacker,
            hit = Calculator.get_hit_chance(defender, attacker),
            dmg = Calculator.get_damage(defender, attacker)
        }
        add(result.steps, step2)
    end

    return result
end

return Calculator