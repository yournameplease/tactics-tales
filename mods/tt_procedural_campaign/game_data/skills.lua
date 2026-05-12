local builders = require("src.tactics.skills.builders")

---@type table<string, SkillDefinition>
return {
    -- Existing skills
    heal = builders.make_heal("Heal", 5, builders.ally_in_range(1, 2, function(u)
        return u.hp_current < u.character.stats.hp_max
    end), { hp_cost = 1 }),

    missile = builders.make_damage("Missile", 3, 100, builders.enemy_in_range(1, 2), {
        uses_per_battle = 1,
    }),

    -- Cultists
    soul_strike = builders.make_damage("Soul Strike", 3, 100, builders.enemy_in_range(1, 2), {
        hp_cost = 1,
    }),

    -- TODO: effect type not yet in engine
    share_life    = { name = "Share Life",    targeting = builders.ally_in_range(1, 1),       effects = {} },
    sacrifice     = { name = "Sacrifice",     targeting = builders.ally_in_range(1, 1),       effects = {} },
    raise_soldier = { name = "Raise Soldier", targeting = builders.ally_in_range(1, 1),       effects = {} },
    blood_siphon  = { name = "Blood Siphon",  targeting = builders.enemy_in_range(1, 1),      effects = {} },
    blood_ritual  = { name = "Blood Ritual",  targeting = builders.self_target(),             effects = {} },

    -- Bandits
    ritual_healing = builders.make_heal("Ritual Healing", 3, builders.self_target()),

    intimidate = builders.make_debuff("Intimidate", "move_lock", 1, builders.enemy_in_range(1, 2), {
        cooldown = 3,
    }),

    mark_prey = {
        name      = "Mark Prey",
        cooldown  = 3,
        targeting = builders.enemy_in_range(1, 2),
        effects   = { { type = "debuff", kind = "mark", amount = 1, duration = 1 } },
    },

    war_cry = builders.make_buff("War Cry", "double_attack", 1, builders.self_target(), {
        uses_per_battle = 1,
    }),

    rampage = {
        name            = "Rampage",
        uses_per_battle = 1,
        targeting       = builders.adjacent_enemies(),
        effects         = {
            { type = "damage", damage = 3, accuracy = 100 },
            { type = "debuff", kind = "skip_turn", duration = 1, self_target = true },
        },
    },

    -- Militia
    militia_heal = builders.make_heal("Militia Heal", 4, builders.ally_in_range(1, 1), {
        cooldown = 3,
    }),

    field_healing = builders.make_heal("Field Healing", 1, builders.adjacent_allies(), {
        cooldown = 3,
    }),

    mass_heal = builders.make_heal("Mass Heal", 2, builders.allies_in_range(1, 2), {
        uses_per_battle = 1,
    }),

    hold_the_line = {
        name      = "Hold the Line",
        cooldown  = 3,
        targeting = builders.adjacent_allies(),
        effects   = { { type = "buff", kind = "defense_bonus", amount = 1, duration = 1 } },
    },

    rally = {
        name            = "Rally",
        cooldown        = 2,
        uses_per_battle = 1,
        targeting       = builders.ally_in_range(1, 1),
        effects         = { { type = "refresh_action" } },
    },

    advance_formation = {
        name      = "Advance Formation",
        targeting = builders.adjacent_allies(),
        effects   = { { type = "buff", kind = "move_bonus", amount = 1, duration = 1 } },
    },

    wither = {
        name      = "Wither",
        cooldown  = 2,
        targeting = builders.enemy_in_range(1, 2),
        effects   = { { type = "debuff", kind = "damage_reduction", amount = 1, duration = 2 } },
    },
}
