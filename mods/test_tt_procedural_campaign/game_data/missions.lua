local battle_lib = include("mods/base/lib/battle.lua")
local battle     = battle_lib.battle

local character_source = battle.character_source
local ai <const>       = battle.ai

---@type ModMissionsModule
local missions = {
    -- Seize layout smoke test: player deploys south, enemy commander holds north.
    abandoned_fortress_seize = function(_campaign_config)
        return {
            map_id = "abandoned_fortress",
            victory_conditions = { battle.victory.rout() },
            failure_conditions = {},
            units = {
                { side = "player", layer = "deployment_seize", slots = {
                    default = { character_source = character_source.template("test_fighter") },
                }},
                { side = "enemy", layer = "boss_seize", slots = {
                    enemy_commander = { character_source = character_source.template("test_armed_enemy"), ai = ai.stationary },
                }},
            },
            scripts = {},
        }
    end,
}

return missions
