local battle_lib = include("mods/base/lib/battle.lua")
local battle     = battle_lib.battle

local character_source = battle.character_source
local ai <const>       = battle.ai

---@type ModMissionsModule
local missions = {
    -- Seize layout smoke test: player deploys south, enemy commander holds north.
    -- Requires TASK-47 (active_labels support in map_generator) to load correctly.
    abandoned_fortress_seize = function(_campaign_config)
        return {
            map_id        = "abandoned_fortress",
            active_labels = { "deployment_seize", "boss_seize" },
            tile_labels   = {},
            victory_conditions = { battle.victory.rout() },
            failure_conditions = {},
            units = {
                { side = "player", character_source = character_source.template("test_fighter"),     tile = "deployment_seize" },
                { side = "enemy",  character_source = character_source.template("test_armed_enemy"), tile = "boss_seize", ai = ai.stationary },
            },
            scripts = {},
        }
    end,
}

return missions
