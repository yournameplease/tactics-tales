---
id: TASK-45
title: 'Map: author abandoned_fortress in Tiled as pipeline reference sample'
status: Done
assignee: []
created_date: '2026-04-28 03:09'
updated_date: '2026-05-04 03:31'
labels: []
milestone: m-9
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Author `abandoned_fortress` in Tiled as the reference implementation for the Tiled map pipeline (serves as the sample until a dedicated playground map is created). This is the prerequisite that unblocks the converter and engine tasks.

**Tiled project setup:**
- Tile size: 16×16 to match Picotron
- Snap to grid enabled on object layers
- Single tileset: `tiny_tileset.tsx` only (`town_grass_path.tsx` is vestigial — remove it)

**Tile layers** (must use these exact names):
`floor`, `back_walls`, `mid_walls`, `front_walls`, `ceiling`
Currently named "Tile Layer 1" and "Tile Layer 2" — rename accordingly. Layer 1 → `floor`, Layer 2 → `front_walls` (confirm visually).

**Object layers** — one per Spawn Group, named by label (e.g. `deployment_defense`, `boss_seize`). Each object is a point snapped to the tile grid. Layer names are arbitrary; the Mission definition references them by name.

Per-object properties (override layer defaults):
- `slot` — role tag resolved to a character template at runtime
- `facing` — `"left"` or `"right"`
- `ai_hint` — default AI behaviour hint (e.g. `"stationary"`, `"aggressive"`)

Per-layer properties (set defaults inherited by all objects in the layer):
- Same keys as per-object properties: `slot`, `facing`, `ai_hint`
- `from` — entry direction for reinforcement layers (e.g. `"west"`); canonical, not inferred from position

**Required update:** Move `ai_hint = "stationary"` and `slot = "enemy_commander"` from the point object in `boss_seize` to the `boss_seize` layer's properties. This demonstrates the layer-defaults pattern.

**Sidecar** `abandoned_fortress_meta.lua` (alongside the .tmx):
```lua
return {
    variant_sets = {}
}
```

The Tiled Lua export of this file is what the converter (TASK-46) consumes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Tiled project configured with 16×16 tile size, snap-to-grid enabled, and only tiny_tileset.tsx referenced
- [x] #2 abandoned_fortress.tmx tile layers are named per spec (floor, front_walls, etc.) matching the visual layout
- [x] #3 boss_seize layer carries ai_hint and slot as layer-level properties; the point object has no redundant per-object overrides
- [x] #4 All Spawn Groups (deployment_defense, deployment_seize, boss_seize, reinforce_west) are object layers with point objects at correct grid positions
- [x] #5 reinforce_west layer has from = "west" as a layer property
- [x] #6 abandoned_fortress_meta.lua sidecar exists alongside the .tmx
- [x] #7 Tiled Lua export produces a valid Lua file loadable with require()
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
