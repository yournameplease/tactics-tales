---@brief
--- Defines the main data structure for a battle.
--- The BattleDefinition record aggregates all components of a battle,
--- including the map, unit spawns, objectives, and scripts.

---@class BattleDeploymentDefinition
---@field deployment_tiles_tag string TileLabel identifying the tiles where player units are placed at battle start.

---@alias BattleDefinitionFactory fun(StoryConfig): BattleDefinition

---@class BattleDefinition
---@field map_id string ID of the map used for this battle.
---@field music integer Music track ID played during this battle.
---@field tile_labels table<TileLabel, integer[]> Maps semantic tile labels to lists of metatile indices.
---@field turn_limit integer Maximum number of turns before the turn-limit failure condition triggers.
---@field victory_conditions VictoryCondition[] Conditions under which the player wins the battle.
---@field failure_conditions FailureCondition[] Conditions under which the player loses the battle.
---@field deployment BattleDeploymentDefinition Defines where player units are placed at battle start.
---@field units UnitSpawnData[] Units that are spawned when the battle begins.
---@field scripts BattleScript[] Scripts that define event-driven behaviour for this battle.

local battle_definition = {
}

return battle_definition
