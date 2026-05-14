---
id: TASK-126
title: Add disabled flag to BattleUnit
status: Done
assignee: []
created_date: '2026-05-14 14:02'
updated_date: '2026-05-14 22:13'
labels: []
milestone: m-19
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `---@field disabled boolean` to the `BattleUnit` class annotation in `src/tactics/battle/tactics/battle_unit.lua`, alongside `has_acted` and `marked`. Initialize it to `false` in `BattleUnit.new()`.

This is the foundation for the room/disabled-units feature. All other tasks in the milestone depend on this field existing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `BattleUnit` has a `disabled boolean` field annotated alongside `has_acted` and `marked`
- [x] #2 `disabled` is initialized to `false` in `BattleUnit.new()`
- [x] #3 `make test` passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
