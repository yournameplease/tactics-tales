return {
    id = "test_tt_procedural_campaign",
    name = "Test: Tactics Tales Procedural Campaign",
    description = "Integration test fixtures for the tt_procedural_campaign mod.",
    version = "0.1.0",
    dependendcies = {"test_base", "tt_procedural_campaign"},
    content = {
        missions        = "game_data/missions",
        campaigns       = "game_data/campaigns",
        default_campaign = "abandoned_fortress_seize",
        campaign_select  = { "abandoned_fortress_seize" },
    },
}
