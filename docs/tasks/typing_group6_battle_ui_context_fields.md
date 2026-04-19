---
source_file: src/tactics/battle/battle_ui_context.lua
line: 1
todo_text: "fix type errors: undefined context fields"
slug: typing_group6_battle_ui_context_fields
created: 2026-04-19
---

# Typing Group 6: battle_ui_context.lua — undefined context fields (~13 errors)

**File:** `src/tactics/battle/battle_ui_context.lua`

## Error Summary

All `undefined-field` on context/state objects:
- `point`, `path` — position/movement state fields
- `target_unit`, `acting_unit`, `acting_side` — unit/side state fields
- `destination` — movement destination field
- `tile_highlights` — map display field

## Root Cause

Same pattern as Group 2 (battle_menu_manager): a context object passed around or built up at runtime has fields that aren't declared in its LuaCATS type.

## Pre-Planning Step (do this first)

1. Run `make check 2>&1 | grep 'battle_ui_context\.lua' | grep 'undefined-field'` for current full list
2. Find the type declarations for the context objects accessed at those lines
3. Add missing field annotations to the type, or add `---@as` casts at access sites if the type can't be extended
4. Cross-reference with Group 2 — some of these may be the same context type

## Notes

<!-- Add design notes or user answers here. -->
