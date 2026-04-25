---
id: TASK-7
title: Add UNIT_COMBAT event and per-unit combat tracking
status: Done
assignee: []
created_date: '2026-04-25 16:02'
updated_date: '2026-04-25 17:09'
labels: []
milestone: m-1
dependencies: []
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Emit a new `UNIT_COMBAT` event on every attack exchange and count combats per unit in `StatsService`.

Files to modify:
- `src/tactics/battle/events.lua` — add `UnitCombatPayload` type: `{ attacker_id: UnitId, defender_id: UnitId, chapter: integer }`
- `src/tactics/battle/tactics/tactics_engine.lua` — in `TacticsEngine:do_combat()`, emit `UNIT_COMBAT` after computing the combat result, carrying `attacker.id`, `defender.id`, `self.chapter`
- `src/tactics/story/statistics/stats_service.lua` — add `unit_combats: table<UnitId, integer>` map to `story_results`; register a `UNIT_COMBAT` listener that increments both `attacker_id` and `defender_id` entries
- `src/tactics/story/statistics/story_statistics.lua` — add `unit_combats` field to `StoryResults` or `StoryStatistics` type

Note: Both participants (attacker and defender) get +1 per exchange.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 After a combat exchange, both the attacking unit's and defending unit's combat counts are incremented by 1.
- [x] #2 UNIT_COMBAT is emitted from do_combat in tactics_engine.lua.
- [x] #3 Unit tests cover the StatsService listener and verify both participants are counted.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
