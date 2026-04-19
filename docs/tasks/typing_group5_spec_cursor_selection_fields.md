---
source_file: src/spec/tactics/menu/cursor/nested/grid_spec.lua
line: 1
todo_text: "fix type errors: cursor/selection state missing fields in specs"
slug: typing_group5_spec_cursor_selection_fields
created: 2026-04-19
---

# Typing Group 5: cursor/selection spec files — undefined fields (~40 errors)

**Files:**
- `src/spec/tactics/menu/cursor/nested/grid_spec.lua`
- `src/spec/tactics/menu/cursor/nested/list_spec.lua`
- `src/spec/tactics/menu/cursor/selection_spec.lua`

## Error Summary

- `grid_spec.lua`: `undefined-field` for `point` and `path` on cursor state objects
- `list_spec.lua`: `undefined-field` for `i` and `get_selected_value`
- `selection_spec.lua`: `undefined-field` for `get_selected_value` (many occurrences)

## Root Cause

The cursor/selection state types returned by the cursor modules are missing field/method declarations for `point`, `path`, `i`, and `get_selected_value`. These are likely declared in the implementation but not reflected in the LuaCATS annotations on the return types.

## Pre-Planning Step (do this first)

1. Run `make check 2>&1 | grep -E 'grid_spec|list_spec|selection_spec' | grep 'undefined-field'` for current full list
2. Find the source modules that return cursor/selection state (follow the `require` in each spec)
3. Check whether `point`, `path`, `i`, `get_selected_value` exist in the implementation and just need annotating, or are genuinely missing
4. Add the missing field/method annotations to the cursor/selection state types
5. Work the fixes — these are spec-only and low risk

## Notes

<!-- Add design notes or user answers here. -->
