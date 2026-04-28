---
id: TASK-45
title: 'Map: author playground.map in Tiled as migration sample'
status: To Do
assignee: []
created_date: '2026-04-28 03:09'
labels: []
milestone: m-9
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Author the existing `playground` map in Tiled to serve as the reference implementation for the Tiled map pipeline. This is the prerequisite that unblocks the converter and engine tasks.

**Tiled project setup:**
- Tile size must match Picotron's tile size
- Snap to grid enabled on object layers

**Tile layers** (same names the engine expects):
`floor`, `back_walls`, `mid_walls`, `front_walls`, `ceiling`

**Object layers** — one per spawn group, named by label (e.g. `player_deployment`, `enemy_inf_a`, `recruit_slot`). Each object is a point snapped to the tile grid.

Per-object properties:
- `slot` — role tag resolved to a character template at runtime (e.g. `"enemy_commander"`)
- `facing` — `"left"` or `"right"`
- `ai_hint` — default AI behaviour hint (e.g. `"stationary"`, `"aggressive"`)

Per-layer properties:
- `from` — entry direction for mid-battle reinforcement layers (e.g. `"west"`)

**Sidecar** `playground_meta.lua` (alongside the .tmx):
```lua
return {
    variant_sets = {}  -- no variants needed for playground
}
```
Variant sets declare mutually exclusive spawn group layers and per-variant flags (e.g. `turncoat_eligible`). Keys are Tiled layer names; the set name is used by battle definitions to select a variant at runtime.

The Tiled Lua export of this file is what the converter (next task) consumes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Tiled project configured with correct tile size and snap-to-grid enabled
- [ ] #2 playground.tmx has all five tile layers (floor, back_walls, mid_walls, front_walls, ceiling) populated to match the existing Picotron map
- [ ] #3 All spawn points from the existing metatile layer are represented as named object layers with point objects at correct grid positions
- [ ] #4 playground_meta.lua exists alongside the .tmx (return {} is fine for this map)
- [ ] #5 Tiled Lua export produces a valid Lua file that can be loaded with require()
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
