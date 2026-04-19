# Task: Annotate tt_fantasy_demo_story game_data files

## Goal
Add `---@return` annotations to each content file so LLS can verify the
mod's data matches the engine's expected types. Also add inline
`---@param`/`---@return` to the local helper functions (`shield`, `armor`,
`effect.*`) in items.lua.

## Files
- mods/tt_fantasy_demo_story/game_data/maps.lua
- mods/tt_fantasy_demo_story/game_data/items.lua
- mods/tt_fantasy_demo_story/game_data/battles.lua
- mods/tt_fantasy_demo_story/game_data/characters.lua
- mods/tt_fantasy_demo_story/game_data/stories.lua

## Pattern for each file
Place the `---@return` annotation immediately before the final `return`:

```lua
---@return ModMapsModule       -- maps.lua
---@return ModItemsModule      -- items.lua
---@return ModCharactersModule -- characters.lua
---@return ModBattlesModule    -- battles.lua
---@return ModStoriesModule    -- stories.lua
return DATA_TABLE
```

## Local helpers in items.lua
Add `---@param`/`---@return` to `shield()`, `armor()`, and the `effect.*`
functions:
- `shield()` and `armor()` → `---@return ItemDefinition`
- `effect.increase_defense()` and `effect.increase_avoid()` → `---@return EquipmentEffect`
  (check src/tactics/types/item_definition.lua for the exact type name)

## Prerequisite
mod-types-02-types-d-lua must be complete (ModMapsModule etc. must exist).

## Verification
- Run `make test`.
- Introduce a deliberate type error (e.g. `name = 123` on an item) and
  confirm LLS flags it.
