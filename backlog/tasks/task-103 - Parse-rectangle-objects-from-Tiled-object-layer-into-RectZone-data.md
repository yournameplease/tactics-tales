---
id: TASK-103
title: Parse rectangle objects from Tiled object layer into RectZone data
status: To Do
assignee: []
created_date: '2026-05-09 17:00'
updated_date: '2026-05-09 17:09'
labels: []
milestone: m-16
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend the map loading pipeline to recognise rectangle objects in Tiled object layers alongside the existing point-object handling.

Context: `extract_spawn_groups()` in `src/tactics/battle/map/map_generator.lua` (line 113) currently skips non-point objects (line 127). The key for each group is `layer.name` (line 139), not the object's `name` field — Tiled rectangle objects in practice have `name = ""`. Tiled rectangle objects have pixel `x, y, width, height`; convert to tile coords with `/ tile_w` and `/ tile_h` (same as SpawnPoints on lines 130-131).

Important: the current loop adds `groups[layer.name] = group` for every objectgroup regardless of whether it contains point objects. Rectangle-only layers therefore end up in `spawn_groups` with `points = {}`. The new pass should populate a separate `rect_zones` table using the same `layer.name` key, and should only include layers that contain at least one rectangle object.

Changes needed:
- Define type `RectZone { x: integer, y: integer, w: integer, h: integer }` in `src/tactics/battle/unit/spawn_data.lua`.
- Add a rectangle pass inside `extract_spawn_groups` (or a sibling `extract_rect_zones`); use `layer.name` as the zone key. For each rectangle object, record `{ x = floor(obj.x / tile_w), y = floor(obj.y / tile_h), w = floor(obj.width / tile_w), h = floor(obj.height / tile_h) }`.
- Add field `rect_zones table<string, RectZone>` to `BattleMap` (`src/tactics/battle/battle_map.lua`) and populate it from the generator result.

This is the foundation for the rect-zone-spawning feature; subsequent tasks depend on this data being present on BattleMap.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A spec in map_generator_spec.lua covers a map with a named rectangle object; the parsed map.rect_zones entry has correct tile-coord x, y, w, h values.
- [ ] #2 Existing point-object and spawn_group tests continue to pass.
- [ ] #3 make test is green.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
