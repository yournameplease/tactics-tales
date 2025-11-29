--[[ Data contains:
- map_file or generator
- victory condition
- config
  - specify input for utility map tiles
]]

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
end

global record BattleDefinition
    map_id: string
    victory_conditions: { VictoryCondition }
    failure_conditions: { FailureCondition }
    enemies: { integer: EnemySpawnData }
end

local BATTLE_DATA: { string: BattleDefinition } = {
    ["bandit_village"] = {
        map_id = "bandit_village",
        victory_conditions = { {
            type = "ROUT"
        } },
        failure_conditions = { {
            type = "TURN_LIMIT"
        } },
        enemies = {
            { template = "bandit_goon" },
            { template = "bandit_boss" }
        }
    }
}

return BATTLE_DATA
