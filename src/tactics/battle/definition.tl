---@brief
--- Defines the main data structure for a battle.
--- The BattleDefinition record aggregates all components of a battle,
--- including the map, unit spawns, objectives, and scripts.

local battle_script = require("src.tactics.battle.scripts.battle_script")
local unit_spawn_data = require("src.tactics.battle.unit.spawn_data")
local types = require("src.tactics.battle.definition.types")
local battle_objective = require("src.tactics.battle.definition.objective")

local record BattleDeploymentDefinition
    deployment_tiles_tag: string
end 

local record BattleDefinition
    map_id: string
    music: integer
    tile_labels: { types.TileLabel: {integer} }
    turn_limit: integer
    victory_conditions: { battle_objective.VictoryCondition }
    failure_conditions: { battle_objective.FailureCondition }
    deployment: BattleDeploymentDefinition
    units: { unit_spawn_data.UnitSpawnData}
    scripts: { battle_script.BattleScript }
end

local battle_definition = {
    BattleDefinition = BattleDefinition,
}

return battle_definition
