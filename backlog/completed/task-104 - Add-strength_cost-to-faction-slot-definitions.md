---
id: TASK-104
title: Add strength_cost to faction slot definitions
status: Done
assignee: []
created_date: '2026-05-09 17:00'
updated_date: '2026-05-09 17:47'
labels: []
milestone: m-16
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Faction tiers in `mods/tt_procedural_campaign/game_data/factions.lua` currently map slot tags to plain template-name strings (e.g. `enemy_infantry = "bandit_goon"`). The rect-zone spawning system needs a strength cost per slot tag so it can compute `floor(budget / cost)` unit counts.

Changes needed:
- Add a parallel `costs` table to each faction definition: `costs = { enemy_infantry = 2, enemy_tank = 5, enemy_commander = 8 }`. Keep `tiers` structure unchanged.
- Add type annotations in `mods/types.d.lua`: extend `FactionDefinition` with `costs table<FactionSlotTag, integer>`.
- Add helper `resolve_slot_cost(faction, slot_tag) → integer` in `factions.lua` (exported from the module alongside existing `resolve_slot`). Falls back to 1 if cost is absent.

The existing `resolve_slot()` function must not change signature or behaviour.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 resolve_slot_cost(faction, 'enemy_infantry') returns the correct integer for each defined faction.
- [x] #2 resolve_slot_cost falls back to 1 for an undefined slot tag rather than erroring.
- [x] #3 make test is green.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
