---
id: TASK-112
title: Add role_map and formation fields to faction definitions
status: Done
assignee: []
created_date: '2026-05-11 22:52'
updated_date: '2026-05-11 22:59'
labels: []
milestone: m-17
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add two new fields to each faction definition in `mods/tt_procedural_campaign/game_data/factions.lua`:

**`role_map`** — maps Pod roles to faction slots:
```lua
role_map = {
    patrol  = "enemy_infantry",
    guard   = "enemy_tank",
    ambush  = "enemy_ranged",   -- falls back via faction.fallbacks if slot absent
    boss    = "enemy_commander",
}
```

**`formation`** — formation style for this faction's pods:
```lua
formation = "scattered",  -- all three factions get "scattered" for now
```

Apply to all three factions: `bandits`, `cultists`, `militia`. The resolver will use `faction.role_map[role]` to pick a slot, and fall through to existing `faction.fallbacks` logic when the mapped slot is absent from the tier.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All three factions (bandits, cultists, militia) have role_map and formation fields
- [ ] #2 role_map covers patrol, guard, ambush, boss roles
- [ ] #3 formation = 'scattered' on all factions
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
