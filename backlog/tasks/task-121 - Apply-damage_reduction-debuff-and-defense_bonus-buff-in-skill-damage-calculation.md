---
id: TASK-121
title: >-
  Apply damage_reduction debuff and defense_bonus buff in skill damage
  calculation
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
In `tactics_engine.lua` `skill_action`, when a `damage` effect resolves, check the target's `active_statuses` for a `"damage_reduction"` debuff and a `"defense_bonus"` buff and factor them into the damage applied via `take_damage`.
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
