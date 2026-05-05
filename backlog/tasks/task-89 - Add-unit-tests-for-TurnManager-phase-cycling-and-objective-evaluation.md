---
id: TASK-89
title: Add unit tests for TurnManager phase cycling and objective evaluation
status: To Do
assignee: []
created_date: '2026-05-05 13:19'
labels: []
milestone: m-14
dependencies: []
references:
  - src/tactics/battle/turn_manager.lua
  - src/tactics/battle/battle_manager.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TurnManager and BattleManager have no unit tests — only integration-level coverage via full battle runs. Turn phase cycling (player → neutral → enemy), unit refresh on turn boundary, and Victory/Failure condition evaluation are invisible to unit tests. Bugs in phase ordering only surface mid-battle.

Write unit tests for `TurnManager` using a minimal battle state (small unit list, simple objective). Integration tests for BattleManager service initialization order are a stretch goal.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Phase cycles correctly: player → neutral → enemy → player
- [ ] #2 Turn counter increments after a full cycle
- [ ] #3 Units are refreshed (actions reset) on turn boundary
- [ ] #4 Victory condition met → battle result is victory
- [ ] #5 Failure condition met → battle result is defeat
- [ ] #6 Multiple active objectives: all must resolve before battle ends
- [ ] #7 Existing passing tests remain green
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
