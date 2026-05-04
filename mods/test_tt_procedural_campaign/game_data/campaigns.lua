local campaign_lib = include("mods/base/lib/campaign.lua")
local campaign     = campaign_lib.campaign

---@type ModStoriesModule
local campaigns = {
    data = {
        -- Runs the abandoned_fortress_seize battle then exits. Used to test
        -- tiled-map spawn-group loading once TASK-47 active_labels support lands.
        abandoned_fortress_seize = {
            starting_node = "the_battle",
            battle_config = campaign.static_battle_config{ permadeath = false },
            nodes = {
                the_battle = {
                    campaign.start_battle("abandoned_fortress_seize", { victory = "after", failure = "after" }),
                },
                after = {
                    campaign.exit_campaign(),
                },
            },
        },
    },
}

return campaigns
