# Pod Mission Resolver Design

**Date:** 2026-05-10

## Overview

Replace hand-written unit placement in `missions.lua` with a generic resolver that reads map layer names by prefix and builds mission unit tables automatically. The `village_overrun` mission is the first consumer; future maps can adopt the same conventions.

## Zone Prefix Conventions

Map layers are named with a prefix that determines how the resolver treats them:

| Prefix | Zone type | Resolver behaviour |
|---|---|---|
| `pod_` | rect | Budget-based unit placement; random non-commander slot; count determined by budget share |
| `guard_` | point | One `enemy_tank` (stationary AI) spawned per point; no budget consumed |
| `boss_` | point | One `enemy_commander` spawned per point; no budget consumed |
| `deployment_` | rect | Player deploy zone; selected by the active variant |

## Variant & Exclusion

The map's `*_meta.lua` file is unchanged in structure. Each variant in `variant_sets` names a `deployment` zone and an `excludes` list. The resolver filters out all excluded zones before processing any prefix groups. Exclusions remain manual — map authors control which pods and bosses are suppressed per deployment side.

## Budget & Jitter

```
budget       = base_budget + tier * scale
active_pods  = pod zones not in excludes
base_share   = floor(budget / #active_pods)
variance     = 1   -- tunable constant
pod_budget   = max(0, base_share + rndi(2 * variance + 1) - variance)
```

Each pod rolls its budget independently. Total budget is not strictly enforced; slight overshoot is acceptable and contributes to map variety. `rndi` is assumed to return an integer in `[0, n-1]`, so `rndi(2*variance + 1) - variance` gives a symmetric uniform draw over `[-variance, variance]`.

Pod unit count per zone: `zones.unit_count(pod_budget, resolve_slot_cost(faction, slot))`.

## Slot Selection

For each `pod_` zone the resolver picks a random non-commander slot from the faction's `costs` table (i.e. any key that is not `enemy_commander`). The slot is drawn once per pod via `rng:choose_random_from_list(eligible_slots)`.

## New Module

`mods/tt_procedural_campaign/lib/pod_mission_resolver.lua` exposes a single function:

```lua
build_pod_mission(campaign_config, rng_context, map_context, meta) -> MissionDef
```

It is stateless and pure aside from RNG calls. The function:

1. Resolves faction and tier from `campaign_config`.
2. Picks a variant from `meta.variant_sets` (random via RNG).
3. Builds an exclusion set from the variant's `excludes` list.
4. Iterates `map_context.rect_zones` and `map_context.point_labels`, grouping by prefix.
5. Emits one unit entry per pod zone, guard point, and boss point (non-excluded).
6. Returns the complete `MissionDef` table including `map_id`, objectives, and `point_labels`.

## missions.lua Changes

The `village_overrun` entry becomes a thin wrapper:

```lua
["village_overrun"] = function(campaign_config, rng_context, map_context)
    local meta = include("mods/tt_procedural_campaign/game_data/maps/village_overrun_meta.lua")
    return build_pod_mission(campaign_config, rng_context, map_context, meta)
end,
```

No zone names, slot names, or budget constants appear in `missions.lua`.

## Out of Scope

- Mixed-unit pods (multiple slot types in one pod zone) — deferred.
- Per-zone budget weights in the meta file — deferred; RNG jitter provides initial variety.
- `reinforce_` zones — not addressed by this design.
