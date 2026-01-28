local battle_script = require("src/tactics/battle/scripts/battle_script")
local unit_spawn_data = require("src/tactics/battle/unit/spawn_data")
local types = require("src/tactics/battle/definition/types")
local battle_objective = require("src/tactics/battle/definition/objective")

local record BattleDeploymentDefinition
    deployment_tiles_tag: string
end 

local record BattleDefinition
    map_id: string
    tile_labels: { types.TileLabel: {integer} }
    turn_limit: integer
    victory_conditions: { battle_objective.VictoryCondition }
    failure_conditions: { battle_objective.FailureCondition }
    deployment: BattleDeploymentDefinition
    enemies: { unit_spawn_data.UnitSpawnData}
    neutral: { unit_spawn_data.UnitSpawnData}
    players: { unit_spawn_data.UnitSpawnData}
    scripts: { battle_script.BattleScript }
end

local battle_definition = {
    BattleDefinition = BattleDefinition,
}

return battle_definition
