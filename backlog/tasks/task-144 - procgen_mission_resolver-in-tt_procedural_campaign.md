---
id: TASK-144
title: procgen_mission_resolver in tt_procedural_campaign
status: To Do
assignee: []
created_date: '2026-05-17 00:41'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
  - mods/tt_procedural_campaign/lib/pod_mission_resolver.lua
  - mods/tt_procedural_campaign/game_data/factions.lua
ordinal: 10000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per spec §9.3: add `mods/tt_procedural_campaign/lib/procgen_mission_resolver.lua` (sibling of pod_mission_resolver.lua, which stays as reference). Derives seed from campaign state + battle index, loads the procgen BattleMap, resolves the active faction/tier via existing `factions.lua` API, and expands enemy spawn tile labels into one UnitSpawnData per point using `resolve_slot(faction, tier, role)` as the character template. Emits a single player UnitSpawnData with tile=`player_deployment` and `character_source = player_roster()`. Wire up one test mission and at least one campaign archetype slot that uses it.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Same campaign state + battle index produces the same BattleMap on repeated loads.
- [ ] #2 Each enemy spawn glyph becomes one UnitSpawnData; the role→template mapping uses the active faction's tier table.
- [ ] #3 Player deployment uses tile label player_deployment.
- [ ] #4 A test mission using a procgen MapDefinition is playable end-to-end (load → deploy → fight).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
