---
id: TASK-94
title: Extract unit spawn resolution into unit_spawner module
status: To Do
assignee: []
created_date: '2026-05-05 13:30'
labels: []
milestone: m-14
dependencies: []
references:
  - src/tactics/battle/tactics/tactics_engine.lua
  - src/tactics/character/character_manager.lua
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Two local functions in TacticsEngine — `resolve_character` (tactics_engine.lua:218–236) and `try_spawn_at` (lines 238–283) — handle resolving a `CharacterSource` to a `BattleUnit`. They are already written as free functions (not methods), hidden inside the file. The spawn loop in `spawn_units` (lines 290–338) coordinates them.

Extract to `src/tactics/battle/unit_spawner.lua`. Tests can cover character-source resolution (`"template"` vs `"player_roster"`), blocked-tile behavior (`"prevent"` vs `"spawn_nearby"`), and roster exhaustion — none of which are currently tested.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 New module exports the spawn resolution logic with a testable interface
- [ ] #2 Unit tests: template source always spawns a new character; player_roster source consumes roster entries in order; roster exhausted → unit not spawned; blocked tile + prevent → unit not spawned; blocked tile + spawn_nearby → TODO path noted or implemented
- [ ] #3 TacticsEngine delegates to the new module for spawn resolution
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
