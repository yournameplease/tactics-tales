---
id: TASK-130
title: Merge ceiling_* tile layers at map load time
status: To Do
assignee: []
created_date: '2026-05-14 14:03'
labels: []
milestone: m-19
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Support multiple Tiled ceiling layers (e.g. `ceiling_1`, `ceiling_2`) that represent independent non-overlapping room zones, merging them into the single `terrain.ceiling` layer used by the renderer.

**File:** `src/tactics/battle/map/map_generator.lua`

Replace the `ceiling = opt_layer("ceiling")` line in the `layers` table (around line 246) with a post-construction merge. After building the `layers` table without `ceiling`, iterate `tiled_data.layers` and collect all `tilelayer` entries whose name matches `^ceiling`. Convert each to a userdata with `tiled_layer_to_userdata`, then merge: for each tile position, take the first non-zero value across all collected layers. Assign the result to `layers.terrain.ceiling` (nil if no ceiling layers exist).

The merge approach: create the first matching layer as the base, then for each additional layer copy non-zero tiles into the base. Since zones don't overlap, order doesn't matter.

This is purely a load-time change — the renderer already handles a single optional `terrain.ceiling` layer correctly.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A map with `ceiling_1` and `ceiling_2` layers loads and renders both zones as a single merged ceiling
- [ ] #2 A map with only a plain `ceiling` layer still loads correctly
- [ ] #3 A map with no ceiling layers has `terrain.ceiling = nil` (no regression)
- [ ] #4 `make test` passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
