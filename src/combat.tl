require("src/combat/combat_calculator")

function apply_combat_step(step, battle_state)
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
        battle_state:kill_unit(defender)
    end
end

function do_combat(attacker, defender, battle_state)
    local combat_result = COMBAT_CALCULATOR.compute_combat(attacker, defender, battle_state)

    for i,combat_step in ipairs(combat_result.steps) do
        LOG.debug("Combat step: ",i)
        apply_combat_step(combat_step, battle_state)
    end
end
