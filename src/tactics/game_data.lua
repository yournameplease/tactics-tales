---@brief
--- Defines the main GameData record that aggregates all loaded mod data.

---@class StoryData
---@field data table<StoryId, StoryDefinition> Map of story ID to definition.
---@field default_story StoryId The story loaded by default.
---@field story_select StoryId[] Ordered list of story IDs for selection.

---@class GameData
---@field loaded_mods table<string, boolean> Set of mod names that have been loaded.
---@field maps table<string, MapDefinition>
---@field battles table<string, BattleDefinition>
---@field stories StoryData
---@field characters table<string, CharacterTemplate>
---@field items table<string, ItemDefinition>

local game_data = {}

return game_data
