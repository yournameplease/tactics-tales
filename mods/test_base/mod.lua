return {
    id = "test_base",
    name = "Test Base",
    description = "Minimal shared mod for integration tests.",
    version = "0.1.0",
    dependendcies = {},
    content = {
        maps           = "game_data/maps",
        missions       = "game_data/missions",
        campaigns       = "game_data/campaigns",
        characters     = "game_data/characters",
        items          = "game_data/items",
        default_campaign = "simple_exit",
        campaign_select  = { "simple_exit", "linear_text", "jump_flow", "option_select_and_exit" },
    },
}
