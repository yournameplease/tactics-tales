---
id: TASK-96
title: Create PageFlipAnimator module skeleton
status: To Do
assignee: []
created_date: '2026-05-08 04:31'
labels: []
milestone: m-15
dependencies:
  - TASK-95
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create `src/tactics/animation/page_flip_animator.lua` with the core state machine and public API. No rendering logic yet — just structure.

**States:** `IDLE → PENDING_BEFORE → PENDING_AFTER → ANIMATING → IDLE`

**Public methods:**
- `page_flip_animator.new()` — constructor
- `:begin_flip(direction, callback)` — accepts `"forward"` or `"backward"`, stores callback, transitions `IDLE → PENDING_BEFORE`
- `:tick()` — advances `frame` counter during `ANIMATING`; transitions to `IDLE` when `frame >= 40`
- `:is_active()` — true in any non-IDLE state
- `:is_blocking_input()` — true in `PENDING_BEFORE`, `PENDING_AFTER`, `ANIMATING`
- `:draw(ui_manager, ui_context, draw_target_manager)` — stub, no-op for now
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 begin_flip transitions state from IDLE to PENDING_BEFORE
- [ ] #2 is_blocking_input returns true in all non-IDLE states
- [ ] #3 tick advances frame counter and transitions ANIMATING→IDLE at frame 40
- [ ] #4 begin_flip while already active is a no-op (does not reset state)
- [ ] #5 `make test` passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
