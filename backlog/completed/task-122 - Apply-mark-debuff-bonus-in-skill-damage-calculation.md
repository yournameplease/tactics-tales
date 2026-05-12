---
id: TASK-122
title: Apply mark debuff bonus in skill damage calculation
status: Done
assignee: []
created_date: '2026-05-12 12:43'
updated_date: '2026-05-12 12:54'
labels: []
milestone: m-18
dependencies: []
references:
  - src/tactics/battle/tactics/tactics_engine.lua
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
In `tactics_engine.lua` `skill_action`, when a `damage` effect hits, check the target's `active_statuses` for a `"mark"` debuff and apply any associated bonus damage.
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
