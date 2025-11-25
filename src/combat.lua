function is_in_combat_range(attacker, defender)
    local a_x = attacker.x
    local a_y = attacker.y
    local d_x = defender.x
    local d_y = defender.y
    local min_range = attacker.weapon.min_range
    local max_range = attacker.weapon.max_range
    local dist = abs(a_x-d_x)+abs(a_y-d_y)

    return dist >= min_range and dist <= max_range
end

function apply_combat_step(step)
    local attacker = step.attacker
    local defender = step.defender

    local direction = atan2(
            defender.x - attacker.x,
            defender.y - attacker.y
    )

    attacker:start_animation("BUMP", direction)
    if not step.is_hit then
        defender:start_animation("DODGE", direction + 0.25)
    end
    while attacker.animation_blocking or defender.animation_blocking do
        yield()
    end

    if step.is_hit then
        defender:take_damage(step.dmg)
        defender:start_animation("HURT", direction + 0.5)
    end

    while defender.animation_blocking do
        yield()
    end

    if not defender:is_alive() then
        Battle:kill_unit(defender)
    end
end

function do_combat(attacker, defender)
    local combat_result = COMBAT_CALCULATOR.compute_combat(attacker, defender)

    for i,combat_step in ipairs(combat_result.steps) do
        LOG.debug("Combat step: ",i)
        apply_combat_step(combat_step)
    end
end