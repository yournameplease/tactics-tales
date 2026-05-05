---@type table<string, CharacterTemplate>
return {
    priest = {
        parent_template = "civilian",
        hp_max          = 4,
        item_loadout    = {},
        skill_loadout   = { "heal" },
    },
    mage = {
        parent_template = "civilian",
        hp_max          = 3,
        item_loadout    = { "dagger" },
        skill_loadout   = { "fireball" },
    },

}
