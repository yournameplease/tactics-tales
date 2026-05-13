---@brief
--- Defines the main GameData record that aggregates all loaded mod data.

---@class CampaignData
---@field data table<CampaignId, CampaignDefinition> Map of campaign ID to definition.
---@field default_campaign CampaignId The campaign loaded by default.
---@field campaign_select CampaignId[] Ordered list of campaign IDs for selection.
---@field battle_config fun(CampaignConfig): BattleConfig

---@class GameData
---@field loaded_mods table<string, boolean> Set of mod names that have been loaded.
---@field maps table<string, MapDefinition>
---@field missions table<string, MissionFactory>
---@field campaigns CampaignData
---@field characters table<string, CharacterTemplate>
---@field items table<string, ItemDefinition>
---@field skills table<string, SkillDefinition>
---@field gfx_registry table<string, integer> Maps gfx stem to base sprite index.

local game_data = {}

return game_data
