---@brief
--- Defines the main GameData record that aggregates all loaded mod data.

---@class CampaignData
---@field data table<CampaignId, CampaignDefinition> Map of story ID to definition.
---@field default_campaign CampaignId The story loaded by default.
---@field campaign_select CampaignId[] Ordered list of story IDs for selection.
---@field battle_config fun(StoryConfig): BattleConfig

---@class GameData
---@field loaded_mods table<string, boolean> Set of mod names that have been loaded.
---@field maps table<string, MapDefinition>
---@field battles table<string, BattleDefinitionFactory>
---@field campaigns CampaignData
---@field characters table<string, CharacterTemplate>
---@field items table<string, ItemDefinition>

local game_data = {}

return game_data
