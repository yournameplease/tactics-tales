---
id: TASK-129
title: Support disabled flag in UnitSpawnData
status: To Do
assignee: []
created_date: '2026-05-14 14:03'
labels: []
milestone: m-19
dependencies:
  - TASK-126
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Allow units to be spawned in a disabled state from map data.

**Changes:**

`src/tactics/battle/unit/spawn_data.lua` — add `---@field disabled? boolean` to `UnitSpawnData`. Absent or `false` means enabled (normal behavior).

`src/tactics/battle/tactics/tactics_engine.lua` — in the unit spawn path (around line 238 where `UnitSpawnData` is handled), after the `BattleUnit` is created, apply: `u.disabled = spawn_data.disabled == true`.

This allows mission scripts to pre-place enemies/allies inside rooms as disabled units that don't act or appear until the room is opened.

Depends on TASK-126 (disabled field must exist).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 `UnitSpawnData` has a `disabled? boolean` field annotated
- [ ] #2 Spawning a unit with `disabled = true` results in `unit.disabled == true` on the created `BattleUnit`
- [ ] #3 Spawning without the field (or `disabled = false`) leaves the unit enabled
- [ ] #4 `make test` passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
