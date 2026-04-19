# Task: Create mods/types.d.lua

## Goal
Create the central public contract for mod authors. This file documents
what each game_data content module must return, as a single reference.

## File to create
`mods/types.d.lua`

## Content shape

```lua
---@meta

-- Returned by each mod's mod.lua
---@class ModSpec
---@field id string
---@field name string
---@field version string
---@field dependendcies string[]
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
```

## Notes
- The body types (MapDefinition, ItemDefinition, CharacterTemplate,
  BattleDefinitionFactory, StoryDefinition) are already defined in src/
  and resolved globally by LLS — do not re-declare them here.
- ModSpec and ModContent are the only types fully owned by this file
  (they exist in src/tactics/mods.lua but the mods/ version is the
  public-facing definition).
- ModStoriesModule is declared as a class (not alias) because it is a
  composite record, not simply a table<k,v>.

## Existing src/ references
- MapDefinition: src/tactics/battle/map/types.lua
- ItemDefinition: src/tactics/types/item_definition.lua
- CharacterTemplate: src/tactics/character/definition.lua
- BattleDefinitionFactory: src/tactics/battle/definition.lua
- StoryDefinition: src/tactics/story/types.lua

## Verification
- Run `make test`.
- Hover `ModItemsModule` in an editor; LLS should resolve it to
  `table<string, ItemDefinition>`.
