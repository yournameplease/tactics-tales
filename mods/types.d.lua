---@meta

-- Returned by each mod's mod.lua
---@class ModSpec
---@field id ModId
---@field name string
---@field version string
---@field dependendcies ModId[]
---@field content ModContent

---@class ModContent
---@field maps? string    Relative path (no .map) to the maps data file.
---@field missions? string
---@field campaigns? string
---@field characters? string
---@field items? string
---@field gfx? string[]  Paths (relative to mod root, no extension) to .gfx tileset files.
---@field skills? string Relative path (no extension) to the skills data file.
---@field campaign_select? string[]  Ordered list of campaign IDs shown in Chapter Select. Defaults to all stories.
---@field default_campaign? string   Campaign ID used when starting a new file. Required on at least one mod.

-- Returned by game_data/maps.lua
---@alias ModMapsModule table<string, MapDefinition>

-- Returned by game_data/items.lua
---@alias ModItemsModule table<string, ItemDefinition>

-- Returned by game_data/characters.lua
---@alias ModCharactersModule table<string, CharacterTemplate>

---@class MapContext
---@field rect_zones table<string, RectZone> Named rectangle zones extracted from the map's object layers.
---@field point_zones table<string, Point[]> Named point arrays extracted from the map's object layers.

-- Returned by game_data/missions.lua
---@alias ModMissionsModule table<string, MissionFactory>

-- Returned by game_data/campaigns.lua
---@class ModStoriesModule
---@field data table<string, CampaignDefinition>

---@alias FactionSlotTag "enemy_infantry"
---| "enemy_commander"
---| "enemy_tank"
---| "enemy_ranged"

---@class FactionTier
---@field enemy_infantry? string
---@field enemy_commander? string
---@field enemy_tank? string
---@field enemy_ranged? string

---@class FactionDefinition
---@field name string
---@field tiers FactionTier[]
---@field costs table<FactionSlotTag, integer>
---@field fallbacks table<FactionSlotTag, FactionSlotTag>
---@field recruitable string[] Slot tags (excluding enemy_commander) available for recruitment.

---@class FactionsModule
---@field factions table<string, FactionDefinition>
---@field resolve_slot fun(faction: FactionDefinition, tier_index: integer, slot_tag: FactionSlotTag): string?
---@field resolve_slot_cost fun(faction: FactionDefinition, slot_tag: FactionSlotTag): integer
