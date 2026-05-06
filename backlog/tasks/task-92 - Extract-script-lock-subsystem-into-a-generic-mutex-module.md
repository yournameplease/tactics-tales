---
id: TASK-92
title: Extract script lock subsystem into a generic mutex module
status: Done
assignee: []
created_date: '2026-05-05 13:29'
updated_date: '2026-05-05 13:38'
labels: []
milestone: m-14
dependencies: []
references:
  - src/tactics/battle/tactics/tactics_engine.lua
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The TacticsEngine owns a small lock subsystem: `acquire_lock`, `remove_lock`, `is_locked`, `yield_while_in_script` (tactics_engine.lua:119–131, 853–871), backed by `tactics_locks` table and `id_generator`. This is a general-purpose counted mutex with no battle-specific logic.

Extract to `src/tactics/systems/mutex.lua` (or similar). TacticsEngine holds a `Mutex` instance and delegates. The module is then independently testable with no battle dependencies.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 New module `mutex.lua` exports `mutex.new()` returning a Mutex object
- [ ] #2 Mutex has acquire(), release(id), is_locked() — names may differ from current TacticsEngine methods
- [ ] #3 Unit tests: acquire returns unique IDs; is_locked true while any held; is_locked false after all released; releasing unknown ID is a no-op or errors cleanly
- [ ] #4 TacticsEngine delegates to the Mutex instance
- [ ] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
