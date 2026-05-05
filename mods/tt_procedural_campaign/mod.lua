return {
    id = "tt_procedural_campaign",
    name = "Tactics Tales: Procedural Campaign",
    description = "A procedurally generated run built from archetype-driven encounter sequences.",
    version = "0.1.0",

    dependendcies = {"base", "tactics_puzzler", "tt_fantasy_demo_story"},

    content = {
        maps       = "game_data/maps",
        missions   = "game_data/missions",
        campaigns  = "game_data/campaigns",
        skills     = "game_data/skills",
        characters = "game_data/characters",
        -- items inherited from tt_fantasy_demo_story
        default_campaign = "proc_campaign",
        campaign_select  = { "proc_campaign" },
        gfx = { "game_data/gfx/tiny_tileset" },
    },
}
