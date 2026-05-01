return {
  id = "tt_fantasy_demo_story",
  name = "Tactics Tales: Fantasy Demo Story",
  description = "A simple fantasy story of bandits, cultists, and heroes.",
  version = "0.1.0",

  dependendcies = {"base", "tactics_puzzler"},

  content = {
    maps = "game_data/maps",
    battles = "game_data/battles",
    campaigns       = "game_data/campaigns",
    characters = "game_data/characters",
    items = "game_data/items",
    default_campaign = "demo_story",
    -- I should probably move this to the config param
    -- default_campaign = "convention_demo",
    campaign_select  = {
      "bandit_village",
      "cultist_cave",
      "fortress_town",
      "cliff_crossing",
      "castle_defense",
      "demo_playground",
      "model_room",
    },
  },
}
