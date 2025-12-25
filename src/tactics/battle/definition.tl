local battle_script = require("src/tactics/battle/scripts/battle_script")
local unit_spawn_data = require("src/tactics/battle/unit/spawn_data")
local types = require("src/tactics/battle/definition/types")

local record BattleDefinition
    map_id: string
    tile_labels: { types.TileLabel: {integer} }
    victory_conditions: { types.VictoryCondition }
    failure_conditions: { types.FailureCondition }
    enemies: { unit_spawn_data.UnitSpawnData}
    neutral: { unit_spawn_data.UnitSpawnData}
    players: { unit_spawn_data.UnitSpawnData}
    scripts: { battle_script.BattleScript }
end

local battle_definition = {
    BattleDefinition = BattleDefinition,
}

return battle_definition
