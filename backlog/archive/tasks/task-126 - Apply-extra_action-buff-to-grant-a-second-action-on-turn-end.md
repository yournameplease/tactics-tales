---
id: TASK-126
title: Apply extra_action buff to grant a second action on turn end
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
In `tactics_engine.lua` `finish_unit_action`, check the unit's `active_statuses` for an `"extra_action"` buff. If present, skip marking `has_acted` and consume the buff so the unit gets one additional action.
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
