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
