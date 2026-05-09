---
id: TASK-107
title: Use zone expansion in abandoned_fortress_seize mission factory
status: To Do
assignee: []
created_date: '2026-05-09 17:01'
labels: []
milestone: m-16
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update the `abandoned_fortress_seize` mission factory in `mods/tt_procedural_campaign/game_data/missions.lua` to replace its manual per-layer LayerSpawnData entries with rect-zone expansion, demonstrating the full system end-to-end.

The factory should:
1. Include `mods/base/lib/zones.lua` (TASK-106).
2. Use `map_context.rect_zones` (TASK-105) to look up named zones defined in the `abandoned_fortress` map.
3. Compute unit count: `zones.unit_count(base_budget + tier * scale, resolve_slot_cost(faction, slot))` (TASK-104).
4. Expand zone to Point[]: `zones.expand(rect, "grid", count)`.
5. Return expanded points as entries in `point_labels` and reference them via `UnitSpawnData.tile`.
6. Keep the boss tile as a named point (existing `LayerSpawnData` or metatile label) — do not convert single-unit placements to zones.

The `skirmish` mission may remain on the old API for now.

Depends on TASK-103, TASK-104, TASK-105, TASK-106. Also requires the `abandoned_fortress` map file to have rectangle objects named appropriately (coordinate with map authoring).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 abandoned_fortress_seize mission definition contains point_labels entries derived from rect zones.
- [ ] #2 Unit count scales with tier: a higher tier value produces more units (up to rect capacity).
- [ ] #3 Boss tile is still spawned via a named single-point label, not a zone.
- [ ] #4 make test is green (existing mission tests pass).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
