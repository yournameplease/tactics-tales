---
id: TASK-109
title: Create pod_mission_resolver lib
status: Done
assignee: []
created_date: '2026-05-10 14:04'
updated_date: '2026-05-10 14:23'
labels: []
milestone: m-17
dependencies:
  - TASK-108
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
New file: `mods/tt_procedural_campaign/lib/pod_mission_resolver.lua`

Exposes `build_pod_mission(campaign_config, rng_context, map_context, meta)` which returns a `MissionDefinition`. Depends on TASK-108 (point_zones in map_context).

Design decisions from spec (`docs/superpowers/specs/2026-05-10-pod-mission-resolver-design.md`):
- Pick a variant from `meta.variant_sets` randomly via `rng_context`
- Build exclusion set from the variant's `excludes` list
- Scan `map_context.rect_zones` for `pod_*` prefixes → budget-based placement, random non-commander slot
- Scan `map_context.point_zones` for `guard_*` prefixes → spawn one `enemy_tank` (stationary) per point, no budget
- Scan `map_context.point_zones` for `boss_*` prefixes → spawn one `enemy_commander` per point, no budget
- The deployment zone comes from the active variant's `deployment` field

Budget formula:
```
budget      = base_budget + tier * scale   (base_budget=4, scale=2)
base_share  = floor(budget / #active_pods)
variance    = 1
pod_budget  = max(0, base_share + rndi(2*variance+1) - variance)
```
`rndi(n)` returns an integer in [0, n-1]. Each pod rolls independently.

Slot selection: for each pod, pick a random key from faction.costs excluding "enemy_commander" using rng.

Uses existing utilities:
- `mods/base/lib/zones.lua` — `zones.expand`, `zones.unit_count`
- `mods/tt_procedural_campaign/game_data/factions.lua` — `resolve_slot`, `resolve_slot_cost`, `get_faction`, `get_tier`
- `mods/base/lib/battle.lua` — `character_source`, `ai`, `battle.victory.rout`, `battle.failure.tagged_unit_dies`
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
