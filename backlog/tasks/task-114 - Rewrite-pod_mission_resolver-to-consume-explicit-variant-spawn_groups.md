---
id: TASK-114
title: Rewrite pod_mission_resolver to consume explicit variant spawn_groups
status: To Do
assignee: []
created_date: '2026-05-11 22:52'
labels: []
milestone: m-17
dependencies:
  - TASK-112
  - TASK-113
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the prefix-scan approach in `mods/tt_procedural_campaign/lib/pod_mission_resolver.lua` with one that reads explicit spawn group declarations from the variant.

**New meta format** (consumed, not authored here — see migration task):
```lua
variant_sets = {
    {
        deployment = "deployment_w",
        spawn_groups = {
            { zone = "pod_w",        role = "patrol", facing = "east",  threat_mult = 1.0 },
            { zone = "house_w_guard",role = "guard",  facing = "east" },
            { zone = "boss_sw",      role = "boss",   facing = "north" },
        }
    },
    ...
}
```

**Resolver changes:**
- Remove prefix scanning (`pod_*`, `guard_*`, `boss_*`) — replaced by iterating `variant.spawn_groups`
- Remove `excludes` logic (groups not listed simply don't spawn)
- Per-group budget: `base_pod_budget × (group.threat_mult or 1.0)` — no global split, no jitter
- Role → slot via `faction.role_map[role]`, falling through `faction.fallbacks` as before
- Role behaviour:
  - `patrol`, `ambush` — rect zone, budget-based multi-unit, `ai.move_two`
  - `guard` — point zone, single unit, `ai.stationary`, no budget
  - `boss` — point zone, single unit, `ai.stationary`, tagged `"boss"`, no budget
- Facing: translate `north`→`up`, `south`→`down`, `east`→`right`, `west`→`left`; write to `UnitSpawnData.facing`
- `base_pod_budget` stays tier-derived: `BASE_BUDGET + tier * TIER_SCALE`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 No prefix scanning remains in the resolver
- [ ] #2 Each variant's spawn_groups drives all enemy spawns
- [ ] #3 budget = base_pod_budget * threat_mult per group
- [ ] #4 boss role spawns enemy_commander with boss tag and stationary AI
- [ ] #5 guard role spawns enemy_tank with stationary AI
- [ ] #6 patrol/ambush roles spawn budget-sized unit count from rect zone
- [ ] #7 facing is written to UnitSpawnData
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
