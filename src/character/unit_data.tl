

UNIT_TEMPLATES = {
    human_base = {
        movement = 5,
        hp_max = 5
    },
    bandit_goon = {
        parent = human_base,
        weapon_options = { "club", "axe" }
    },
    bandit_boss = {
        parent = bandit_goon,
        hp_max = 8,
        weapon_options = { "poleaxe" }
    }
}