---
id: TASK-123
title: Apply double_attack buff in do_combat for extra attack step
status: To Do
assignee: []
created_date: '2026-05-12 12:43'
labels: []
milestone: m-18
dependencies: []
references:
  - src/tactics/battle/tactics/tactics_engine.lua
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
In `tactics_engine.lua` `do_combat`, check the attacker's `active_statuses` for a `"double_attack"` buff and grant an additional combat step when present.
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
