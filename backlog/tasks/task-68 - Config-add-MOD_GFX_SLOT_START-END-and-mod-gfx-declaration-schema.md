---
id: TASK-68
title: 'Config: add MOD_GFX_SLOT_START/END and mod gfx declaration schema'
status: To Do
assignee: []
created_date: '2026-05-04 04:32'
labels: []
milestone: m-9
dependencies: []
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add the mod GFX slot range to `STATIC_CONFIG` and extend the mod content spec to allow mods to declare their `.gfx` files.

**Files to modify:**
- `src/tactics/config.lua` — add `MOD_GFX_SLOT_START = 16` and `MOD_GFX_SLOT_END = 31`
- `src/tactics/mods/mod_schema.lua` — add optional `gfx` field (list of strings) to the mod content schema

**Mod declaration format** (path relative to mod root):
```lua
content = {
  gfx = { "game_data/gfx/tiny_tileset" },
  ...
}
```

The `gfx` field is optional; mods that ship no tilesets omit it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 STATIC_CONFIG has MOD_GFX_SLOT_START = 16 and MOD_GFX_SLOT_END = 31
- [ ] #2 mod_schema accepts an optional gfx field containing a list of strings
- [ ] #3 A mod.lua without a gfx field still passes schema validation
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
