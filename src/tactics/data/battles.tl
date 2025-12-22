local unit_ai = require("src/tactics/battle/unit/unit_ai")
local battle_definition = require("src/tactics/battle/definition")

local ai: {string: unit_ai.UnitAI} = {
    default = { move = "two", target = "player"},
    move_one = { move = "one", target = "player"},
    move_two = { move = "two", target = "player"},
    move_inf = { move = "infinity", target = "player"},
    stationary = { move = "zero", target = "player"},
}


global BATTLE_DATA: { string: battle_definition.BattleDefinition } = {
    ["bandit_village"] = {
        map_id = "bandit_village",
        tile_labels = {
            ["player_deployment"] = { 0x01 },
            ["bandit_boss_tile"] = { 0x01 },
            ["bandit_goon_tile"] = { 0x01 },
            ["player_spearman_tile"] = { 0x01 },
            ["player_archer_tile"] = { 0x01 },
            ["player_armor_tile"] = { 0x01 },
        },
        victory_conditions = { {
            type = "ROUT"
        } },
        failure_conditions = { {
            type = "TURN_LIMIT"
        } },
        enemies = {
            { template = "bandit_boss", ai = ai.stationary, tile = "bandit_boss_tile" },
            { template = "bandit_goon", ai = ai.move_two, tile = "bandit_goon_tile" },
        },
        players = {
            { tile = "player_deployment" },
            { template = "militia_spearman", tile = "player_spearman_tile" },
            { template = "militia_archer", tile = "player_archer_tile" },
            { template = "militia_armor", tile = "player_armor_tile" },
        }
    }
}

return BATTLE_DATA
