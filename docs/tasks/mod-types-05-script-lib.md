# Task: Annotate base/lib/script.lua (ScriptBuilder API)

## Goal
Add inline LuaCATS to the ScriptBuilder so mods using it get
autocomplete and type checking for the chained API.

## File
`mods/base/lib/script.lua`

## What to annotate
- `---@class ScriptBuilder` on the builder table/object
- `---@field` for any stored state fields
- Each factory (`script.on_turn`, `script.when_unit_dies`,
  `script.on_talk`, `script.on_tile_interaction`,
  `script.on_adjacent_tile_interaction`) → `---@param`/`---@return ScriptBuilder`
- Each chain method (`:then_spawn_units`, `:then_dialogue`,
  `:then_modify_units`, `:then_recruit_unit`, `:then_modify_terrain`,
  `:then_play_sound`, `:with_tags`, `:as_one_shot`) →
  `---@param`/`---@return ScriptBuilder`
- `script.unit.tagged(unit_tag)`, `script.unit.source()`,
  `script.unit.target()` → `---@return` with an appropriate unit-selector
  type. Check src/tactics/battle/scripts/ for an existing type; if none,
  define `---@alias ScriptUnitSelector` locally.

## Style guide
Follow the annotation style in src/tactics/ — one `---@param` line per
parameter with a brief description, `---@return` on its own line.
Do not change runtime behavior.

## Verification
- Run `make test`.
- Hover a chain call like `script.on_turn(...):then_dialogue(...)` in
  an LLS-enabled editor; should show `ScriptBuilder` as the return type.
