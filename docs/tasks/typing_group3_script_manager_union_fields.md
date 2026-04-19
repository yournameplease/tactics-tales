---
source_file: src/tactics/battle/scripts/script_manager.lua
line: 1
todo_text: "fix type errors: discriminated union command subtype fields"
slug: typing_group3_script_manager_union_fields
created: 2026-04-19
---

# Typing Group 3: script_manager.lua — discriminated union command fields (~30 errors)

**File:** `src/tactics/battle/scripts/script_manager.lua`

## Error Summary

All `undefined-field` — fields of specific script command subtypes accessed without narrowing:
- `repeating`, `phase`, `turn` — trigger/scheduling fields
- `unit_label`, `units`, `unit_selector`, `new_side`, `new_ai` — unit command fields
- `animation`, `blocked_behavior` — animation command fields
- `tile_label`, `new_terrain` — terrain command fields
- `unit`, `text` — dialogue/display fields
- `sound_id`, `tag`, `music_id`, `music_type` — audio fields
- `unit_specifier`, `tile_specifier`, `interaction_text`, `interaction_distance` — interaction fields

## Root Cause

Script commands are a discriminated union. When dispatching based on command type, the checker doesn't narrow to the correct subtype, so accessing subtype-specific fields fails.

## Pre-Planning Step (do this first)

1. Run `make check 2>&1 | grep 'script_manager\.lua' | grep 'undefined-field'` for the current full list
2. Find the union type definition for script commands (grep for the base type)
3. For each command variant, check if a proper subtype with those fields is declared
4. Decide approach: add `---@as ScriptCommandFoo` casts at each dispatch site, or restructure types so the checker can narrow via the discriminant field
5. Create a sub-TODO per command category (trigger, unit, terrain, audio, etc.)
6. Work the fixes, ask for feedback before committing to a cast-heavy vs type-restructure approach

## Notes

<!-- Add design notes or user answers here. -->
