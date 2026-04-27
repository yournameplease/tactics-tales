---
id: TASK-41
title: 'Mod: add recruitable slot-tag list to faction definitions'
status: To Do
assignee: []
created_date: '2026-04-27 13:41'
labels: []
milestone: m-6
dependencies: []
priority: high
ordinal: 500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a recruitable field to each FactionDefinition in mods/tt_procedural_story/game_data/factions.lua.

- recruitable is a flat list of slot tag strings (e.g. {"enemy_infantry", "enemy_tank"})
- Slot tags are resolved against the current tier via the existing resolve_slot function
- All non-commander slots are recruitable for each faction:
  - bandits: {"enemy_infantry", "enemy_tank"}
  - cultists: {"enemy_infantry", "enemy_tank"}
  - militia: {"enemy_infantry", "enemy_tank", "enemy_ranged"}
- Update FactionDefinition LuaCATS annotation to include the new field

Files: mods/tt_procedural_story/game_data/factions.lua
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each faction has a recruitable field listing slot tags
- [ ] #2 enemy_commander is excluded from all recruitable lists
- [ ] #3 FactionDefinition type annotation includes recruitable: string[]
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
