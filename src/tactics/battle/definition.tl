local unit_ai = require("src/tactics/battle/unit/unit_ai")
local battle_script = require("src/tactics/battle/scripts/battle_script")

-- identifier to associate metatiles with semantic meaning
-- multiple ids can go to the same tiles
local type TileLabel = string

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

local record EnemySpawnData
    template: string
    ai: unit_ai.UnitAI
    tile: TileLabel
end

local record PlayerSpawnData
    template: string
    tile: TileLabel
end

local record BattleDefinition
    map_id: string
    tile_labels: { TileLabel: {integer} }
    victory_conditions: { VictoryCondition }
    failure_conditions: { FailureCondition }
    enemies: { EnemySpawnData }
    players: { PlayerSpawnData }
    scripts: { battle_script.BattleScript }
end

local battle_definition = {
    TileLabel = TileLabel,
    EnemySpawnData = EnemySpawnData,
    PlayerSpawnData = PlayerSpawnData,
    BattleDefinition = BattleDefinition,
}

return battle_definition
