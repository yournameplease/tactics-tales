---
id: TASK-87
title: Reduce mocking in battle menu manager spec to test real state transitions
status: To Do
assignee: []
created_date: '2026-05-05 13:19'
labels: []
milestone: m-14
dependencies: []
references:
  - src/spec/tactics/battle/battle_menu_manager_spec.lua
  - src/tactics/battle/battle_menu_manager.lua
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The battle menu manager spec builds 7 mock factories that replace the entire dependency tree. Tests check `opt.next_state` on values returned from those mocks — verifying mock plumbing rather than actual menu navigation. Skill availability (cooldown, uses-remaining) is never exercised against real objects.

Replace stub unit/skill objects with real `battle_unit` and `skill_def` data structures. Test that menu options reflect actual skill state (cooldown active → skill unavailable) and that selecting an option causes the expected state transition.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Mock count reduced — unit and skill inputs use real data structures, not hand-rolled stubs
- [ ] #2 At least one test verifies menu state transitions across two sequential steps (e.g. SELECT_ACTION → SELECT_SKILL_TARGET)
- [ ] #3 Skill cooldown active causes skill option to be absent or disabled
- [ ] #4 Skill with uses-remaining=0 is treated as unavailable
- [ ] #5 Existing passing tests remain green
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
