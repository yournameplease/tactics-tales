---@brief
--- Defines the main data structure for a mission (the authored setup for a single battle).

---@class MissionDeploymentDefinition
---@field deployment_tiles_tag string TileLabel identifying the tiles where player units are placed at battle start.

---@alias MissionFactory fun(CampaignConfig, CampaignRngContext, MapContext): MissionDefinition

---@class MissionDefinition
---@field map_id string ID of the map used for this mission.
---@field music integer Music track ID played during this mission.
---@field tile_labels table<TileLabel, integer[]> Maps semantic tile labels to lists of metatile indices.
---@field point_labels? table<TileLabel, Point[]> Maps semantic tile labels to explicit tile positions (merged after map load).
---@field turn_limit integer Maximum number of turns before the turn-limit failure condition triggers.
---@field victory_conditions VictoryCondition[] Conditions under which the player wins the mission.
---@field failure_conditions FailureCondition[] Conditions under which the player loses the mission.
---@field deployment MissionDeploymentDefinition Defines where player units are placed at battle start.
---@field units UnitSpawnData[] Units that are spawned when the battle begins.
---@field scripts BattleScript[] Scripts that define event-driven behaviour for this mission.
---@field seed? integer RNG seed for procgen map loading; passed to map_generator.load_map.

local battle_definition = {
}

return battle_definition
