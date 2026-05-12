---
id: TASK-125
title: Apply move_bonus buff to increase unit movement range
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
In `tactics_engine.lua` move validation, check the unit's `active_statuses` for a `"move_bonus"` buff and factor the bonus into the reachable-tile calculation.
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
