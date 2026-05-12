local builders = require("src.tactics.skills.builders")

---@type table<string, SkillDefinition>
return {
    heal = builders.make_heal("Heal", 5, builders.ally_in_range(1, 2, function(u)
        return u.hp_current < u.character.stats.hp_max
    end), { hp_cost = 1 }),

    missile = builders.make_damage("Missile", 3, 100, builders.enemy_in_range(1, 2), {
        uses_per_battle = 1,
    }),
}
