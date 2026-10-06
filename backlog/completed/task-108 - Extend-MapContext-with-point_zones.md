---
id: TASK-108
title: Extend MapContext with point_zones
status: Done
assignee: []
created_date: '2026-05-10 14:04'
updated_date: '2026-05-10 14:13'
labels: []
milestone: m-17
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add point object extraction to the map loading pipeline so the pod mission resolver can read `boss_*` and `guard_*` zones, which are point-shape objects in Tiled maps.

Files to modify:
- `mods/types.d.lua` — add `point_zones: table<string, Point[]>` field to `MapContext`
- `src/tactics/battle/map/map_generator.lua` — add `extract_point_zones(map_def)` that iterates objectgroup layers and collects point-shape objects (shape == "point") into named arrays, converting pixel coords to tile coords via tile dimensions
- `src/tactics/battle/battle_manager.lua` — call `extract_point_zones` alongside `extract_rect_zones` and include the result in the `map_context` table passed to mission factories
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
