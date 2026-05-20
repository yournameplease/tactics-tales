---
id: TASK-151
title: Refactor build_units to be label-driven and fix over-emit bug
status: Done
assignee: []
created_date: '2026-05-19 22:50'
updated_date: '2026-05-20 00:04'
labels: []
milestone: m-23
dependencies:
  - TASK-150
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Refactor `build_units` in `mods/tt_procedural_campaign/lib/procgen_mission_resolver.lua`.

**Bug fix:** Currently the function creates one `UnitSpawnData` per point in each label, but `TacticsEngine:spawn_units` already iterates all points for a given tile label itself. This causes duplicate spawn attempts. Fix: emit exactly one `UnitSpawnData` per label (not per point).

**Label-driven loop:** Replace the hardcoded `ENEMY_ROLES` iteration with a loop over `battle_map.tile_labels`. For each label:
1. Look up `battle_map.spawn_label_meta[label]` to get `{role, tags?}`
2. Skip labels whose role is `"player"` or which have no meta entry
3. Call `resolve_slot(faction, tier, meta.role)` to get the template
4. Emit one `UnitSpawnData` with `tile=label`, `tags=meta.tags` (if present), and the appropriate `ai_mode`

**AI mode:** Keep the existing per-role ai_mode mapping (infantry/ranged/tank → `move_two`, commander → `stationary`). This can be a local lookup table keyed by role.

Depends on TASK-150 (spawn_label_meta must exist on BattleMap).
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
