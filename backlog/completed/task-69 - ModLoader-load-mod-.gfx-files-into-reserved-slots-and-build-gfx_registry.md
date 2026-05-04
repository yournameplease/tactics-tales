---
id: TASK-69
title: 'ModLoader: load mod .gfx files into reserved slots and build gfx_registry'
status: Done
assignee: []
created_date: '2026-05-04 04:33'
updated_date: '2026-05-04 05:01'
labels: []
milestone: m-9
dependencies:
  - TASK-68
priority: high
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend `ModLoader` to copy mod `.gfx` files into the cartridge's `gfx/` directory at the correct slot indices and expose a `gfx_registry` in `game_data`.

**Files to modify:**
- `src/tactics/mods/mod_loader.lua` — add `ModLoader:load_mod_gfx()`, called at the top of `load_mod_data()`
- `.gitignore` — exclude generated gfx files in slots 16–31

**load_mod_gfx() behaviour:**
1. Collect all `gfx` paths from registered mods in registration order
2. Hard error if total count exceeds `MOD_GFX_SLOT_END - MOD_GFX_SLOT_START + 1` (16)
3. Assign each file a slot: first file → slot 16, second → slot 17, etc.
4. Copy `mods/<mod_id>/<path>.gfx` → `tactics.p64/gfx/<slot>_<stem>.gfx` (always overwrite)
5. Build `game_data.gfx_registry = { [stem] = slot * 256, ... }` where stem is the filename without extension

**Gitignore patterns to add:**
```
tactics.p64/gfx/1[6-9]_*.gfx
tactics.p64/gfx/2[0-9]_*.gfx
tactics.p64/gfx/3[01]_*.gfx
```
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 load_mod_gfx() is called before any other loading in load_mod_data()
- [x] #2 Each declared .gfx file is copied to tactics.p64/gfx/<slot>_<stem>.gfx on startup, overwriting any existing file
- [x] #3 game_data.gfx_registry maps each stem to its base sprite index (slot * 256)
- [x] #4 Registering more than 16 total gfx files across all mods raises a clear error before any loading
- [x] #5 Mods with no gfx field are silently skipped
- [x] #6 Generated gfx files (slots 16-31) are covered by .gitignore
- [x] #7 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
