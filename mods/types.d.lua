---@meta

-- Returned by each mod's mod.lua
---@class ModSpec
---@field id ModId
---@field name string
---@field version string
---@field dependendcies ModId[]
---@field content ModContent

---@class ModContent
---@field maps? string    Relative path (no .lua) to the maps data file.
---@field battles? string
---@field stories? string
---@field characters? string
---@field items? string

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
---@field default_story string
---@field story_select string[]
