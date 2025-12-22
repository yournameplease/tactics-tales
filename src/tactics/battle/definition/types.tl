local unit_ai = require("src/tactics/battle/unit/unit_ai")

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

local battle_definition_types = {
    TileLabel = TileLabel,
	VictoryCondition = VictoryCondition,
	FailureCondition = FailureCondition,
    EnemySpawnData = EnemySpawnData,
    PlayerSpawnData = PlayerSpawnData,
}

return battle_definition_types
