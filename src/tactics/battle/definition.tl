local battle_script = require("src/tactics/battle/scripts/battle_script")
local types = require("src/tactics/battle/definition/types")

local record BattleDefinition
    map_id: string
    tile_labels: { types.TileLabel: {integer} }
    victory_conditions: { types.VictoryCondition }
    failure_conditions: { types.FailureCondition }
    enemies: { types.EnemySpawnData }
    neutral: { types.NeutralSpawnData }
    players: { types.PlayerSpawnData }
    scripts: { battle_script.BattleScript }
end

local battle_definition = {
    BattleDefinition = BattleDefinition,
}

return battle_definition
