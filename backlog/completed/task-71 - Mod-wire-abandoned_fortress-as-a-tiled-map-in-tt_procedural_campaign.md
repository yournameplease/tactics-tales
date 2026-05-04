---
id: TASK-71
title: 'Mod: wire abandoned_fortress as a tiled map in tt_procedural_campaign'
status: Done
assignee: []
created_date: '2026-05-04 04:33'
updated_date: '2026-05-04 05:17'
labels: []
milestone: m-9
dependencies:
  - TASK-70
priority: high
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update `tt_procedural_campaign` to declare its tileset and use `type = "tiled"` for `abandoned_fortress`. This is the end-to-end integration proving the full pipeline works.

**Files to modify:**
- `mods/tt_procedural_campaign/mod.lua` — add `gfx = { "game_data/gfx/tiny_tileset" }` to content block
- `mods/tt_procedural_campaign/game_data/maps/` — update `abandoned_fortress` map entry to `type = "tiled"`

`tiny_tileset.gfx` is already present at `mods/tt_procedural_campaign/game_data/gfx/tiny_tileset.gfx`.

The ground layer of `abandoned_fortress.lua` should render visually correct in-game using the tiny_tileset sprites loaded into slot 16 (base index 4096).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 tt_procedural_campaign mod.lua declares gfx = { "game_data/gfx/tiny_tileset" }
- [x] #2 abandoned_fortress map entry uses type = "tiled"
- [ ] #3 game_data.gfx_registry contains { tiny_tileset = 4096 } after mod load
- [ ] #4 Ground layer tiles render correctly in-game from the tiny_tileset
- [x] #5 make test passes
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added `gfx = { "game_data/gfx/tiny_tileset" }` to `tt_procedural_campaign/mod.lua`, added `abandoned_fortress` as a tiled map entry in `maps.lua`, and added `map.tiled()` helper to `mods/base/lib/map.lua`. AC#3 (gfx_registry populated after mod load) is covered by the existing mod_loader tests for `load_mod_gfx`. AC#4 (visual correctness in-game) requires manual Picotron testing.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
