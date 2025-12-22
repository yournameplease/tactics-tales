--[[ Data contains:
- map_file or generator
- victory condition
- config
  - specify input for utility map tiles
]]

local unit_ai = require("src/tactics/battle/unit/unit_ai")

local enum VictoryConditionType
        "ROUT"
        "DEFEAT_BOSS"
        "SURVIVE"
        "ESCAPE"
end

local interface VictoryCondition
    type: VictoryConditionType
end


local enum FailureConditionType
    "LEADER_DIES"
    "TURN_LIMIT"
end

local interface FailureCondition
    type: FailureConditionType
end

global record EnemySpawnData
    template: string
    ai: unit_ai.UnitAI
end

global record PlayerSpawnData
    template: string
end

global record BattleDefinition
    map_id: string
    victory_conditions: { VictoryCondition }
    failure_conditions: { FailureCondition }
    enemies: { integer: EnemySpawnData }
    players: { integer: PlayerSpawnData }
end

local ai: {string: unit_ai.UnitAI} = {
    default = { move = "two", target = "player"},
    move_one = { move = "one", target = "player"},
    move_two = { move = "two", target = "player"},
    move_inf = { move = "infinity", target = "player"},
    stationary = { move = "zero", target = "player"},
}


global BATTLE_DATA: { string: BattleDefinition } = {
    ["bandit_village"] = {
        map_id = "bandit_village",
        victory_conditions = { {
            type = "ROUT"
        } },
        failure_conditions = { {
            type = "TURN_LIMIT"
        } },
        enemies = {
            { template = "bandit_boss", ai = ai.stationary },
            { template = "bandit_goon", ai = ai.move_two },
        },
        players = {
            [2] = { template = "militia_spearman" },
            [3] = { template = "militia_archer" },
            [4] = { template = "militia_armor" },
        }
    }
}

return BATTLE_DATA
