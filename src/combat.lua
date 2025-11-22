include "tasks.lua"

function is_in_combat_range(attacker, defender)
    local a_x = attacker.x
    local a_y = attacker.y
    local d_x = defender.x
    local d_y = defender.y
    local min_range = attacker.stats.min_range
    local max_range = attacker.stats.max_range
    local dist = abs(a_x-d_x)+abs(a_y-d_y)

    return dist >= min_range and dist <= max_range
end

function deal_damage(attacker, defender)
    defender:take_damage(attacker.stats.damage)
end

function can_counterattack(defender, attacker)
    return is_in_combat_range(defender, attacker)
            and defender:is_alive()
            and attacker:is_alive()
end

function apply_combat_step(step)
    local attacker = step.attacker
    local defender = step.defender

    local direction = atan2(
            attacker.x - defender.x,
            attacker.y - defender.y
    )

    attacker:start_animation("BUMP", direction)
    --	if not step.hit then
    --		defender:start_animation("DODGE", direction)
    --	end
    while attacker.animation_playing or defender.animation_playing do
        yield()
    end

    if step.hit then
        deal_damage(attacker, defender)
        defender:start_animation("HURT", direction + 0.5)
    end

    while defender.animation_playing do
        yield()
    end

    if not defender:is_alive() then
        Battle:kill_unit(defender)
    end
end

function do_combat(attacker, defender)
    local combat_result = COMBAT_CALCULATOR.compute_combat(attacker, defender)

    for i,combat_step in ipairs(combat_result.steps) do
        apply_combat_step(combat_step)
    end
end