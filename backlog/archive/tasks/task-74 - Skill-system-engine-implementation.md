---
id: TASK-74
title: Skill system engine implementation
status: To Do
assignee: []
created_date: '2026-05-04 21:48'
labels: []
milestone: m-13
dependencies:
  - TASK-73
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the Skill system engine from the spec produced in the design session (TASK-73). Character carries a known Skills list (persistent); Unit tracks cooldown-remaining and uses-remaining state for the current battle. Engine exposes Skills as a battle action type in the action menu. Specific skill behaviors (healing, damaging, etc.) are defined in mod data — no hardcoded skills in the engine.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Character data supports a known Skills list
- [ ] #2 Unit tracks per-skill cooldown-remaining and uses-remaining for the current battle
- [ ] #3 Skills appear as a usable action in the battle menu when available
- [ ] #4 Turn-based cooldown and per-battle use limit both enforced correctly
- [ ] #5 HP cost is applied on cast; self-kill is allowed
- [ ] #6 Mod-defined skill data schema matches spec
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
