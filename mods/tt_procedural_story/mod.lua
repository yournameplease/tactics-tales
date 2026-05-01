return {
    id = "tt_procedural_story",
    name = "Tactics Tales: Procedural Story",
    description = "A procedurally generated run built from archetype-driven encounter sequences.",
    version = "0.1.0",

    dependendcies = {"base", "tactics_puzzler", "tt_fantasy_demo_story"},

    content = {
        maps     = "game_data/maps",
        battles  = "game_data/battles",
        campaigns       = "game_data/campaigns",
        -- items and characters inherited from tt_fantasy_demo_story
        default_campaign = "proc_story",
        campaign_select  = { "proc_story" },
    },
}
