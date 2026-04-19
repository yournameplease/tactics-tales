# Task: Annotate test_base game_data files

## Goal
Same treatment as mod-types-03 but for the test_base mod's content files.

## Files
- mods/test_base/game_data/maps.lua
- mods/test_base/game_data/items.lua
- mods/test_base/game_data/battles.lua
- mods/test_base/game_data/characters.lua
- mods/test_base/game_data/stories.lua

## Pattern
Place `---@return Mod*Module` immediately before each final `return`:

```lua
---@return ModMapsModule       -- maps.lua
---@return ModItemsModule      -- items.lua
---@return ModCharactersModule -- characters.lua
---@return ModBattlesModule    -- battles.lua
---@return ModStoriesModule    -- stories.lua
return DATA_TABLE
```

Note: test_base/game_data/items.lua may be empty or minimal — check
before annotating; skip if the file returns an empty table.

## Prerequisite
mod-types-02-types-d-lua must be complete.

## Verification
- Run `make test`.
