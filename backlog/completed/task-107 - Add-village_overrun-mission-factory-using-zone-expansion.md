---
id: TASK-107
title: Add village_overrun mission factory using zone expansion
status: Done
assignee: []
created_date: '2026-05-09 17:01'
updated_date: '2026-05-09 18:07'
labels: []
milestone: m-16
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a `village_overrun` mission factory to `mods/tt_procedural_campaign/game_data/missions.lua`, demonstrating the full zone-expansion system end-to-end.

The factory should:
1. Include `mods/base/lib/zones.lua` (TASK-106).
2. Use `map_context.rect_zones` (TASK-105) to look up named zones defined in the `village_overrun` map.
3. Compute unit count: `zones.unit_count(base_budget + tier * scale, resolve_slot_cost(faction, slot))` (TASK-104).
4. Expand zone to Point[]: `zones.expand(rect, "grid", count)`.
5. Return expanded points as entries in `point_labels` and reference them via `UnitSpawnData.tile`.
6. Keep the boss tile as a named single-point label (hardcoded from the `boss_ne` point object at tile 15,4) — do not convert single-unit placements to zones.

The `abandoned_fortress_seize` mission may remain on the old API.

The `village_overrun` map has the following zones available:
- Rectangle zones (for expansion): `deployment_w`, `pod_sw`, `pod_w`, `pod_nw`, `pod_se`, `pod_e`, `pod_s`, `wall_n`, `wall_s`
- Point objects (single-unit): `boss_sw` (tile 1,13), `boss_se` (tile 15,13), `boss_ne` (tile 15,4)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 village_overrun mission factory exists in missions.lua and returns map_id = "village_overrun".
- [x] #2 point_labels in the returned definition contains entries derived from rect zones (enemy infantry and tank squads).
- [x] #3 Unit count scales with tier: a higher tier value produces more units in point_labels (up to rect capacity).
- [x] #4 Boss tile is a single point in point_labels, not a zone-expanded list.
- [x] #5 make test is green (existing seize and skirmish tests still pass).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
