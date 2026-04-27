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
---@field battles? string
---@field stories? string
---@field characters? string
---@field items? string
---@field story_select? string[]  Ordered list of story IDs shown in Chapter Select. Defaults to all stories.
---@field default_story? string   Story ID used when starting a new file. Required on at least one mod.

-- Returned by game_data/maps.lua
---@alias ModMapsModule table<string, MapDefinition>

-- Returned by game_data/items.lua
---@alias ModItemsModule table<string, ItemDefinition>

-- Returned by game_data/characters.lua
---@alias ModCharactersModule table<string, CharacterTemplate>

-- Returned by game_data/battles.lua
---@alias ModBattlesModule table<string, BattleDefinitionFactory>

-- Returned by game_data/stories.lua
---@class ModStoriesModule
---@field data table<string, StoryDefinition>

---@alias FactionSlotTag "enemy_infantry"|"enemy_commander"|"enemy_tank"|"enemy_ranged"

---@class FactionTier
---@field enemy_infantry? string
---@field enemy_commander? string
---@field enemy_tank? string
---@field enemy_ranged? string

---@class FactionDefinition
---@field name string
---@field tiers FactionTier[]
---@field fallbacks table<FactionSlotTag, FactionSlotTag>
---@field recruitable string[] Slot tags (excluding enemy_commander) available for recruitment.

---@class FactionsModule
---@field factions table<string, FactionDefinition>
---@field resolve_slot fun(faction: FactionDefinition, tier_index: integer, slot_tag: FactionSlotTag): string?
