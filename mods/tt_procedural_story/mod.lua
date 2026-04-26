return {
    id = "tt_procedural_story",
    name = "Tactics Tales: Procedural Story",
    description = "A procedurally generated run built from archetype-driven encounter sequences.",
    version = "0.1.0",

    dependendcies = {"base", "tactics_puzzler", "tt_fantasy_demo_story"},

    content = {
        maps     = "game_data/maps",
        battles  = "game_data/battles",
        stories  = "game_data/stories",
        -- items and characters inherited from tt_fantasy_demo_story
        default_story = "proc_story",
        story_select  = { "proc_story" },
    },
}
