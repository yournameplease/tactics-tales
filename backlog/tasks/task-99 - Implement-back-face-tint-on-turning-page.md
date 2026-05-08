---
id: TASK-99
title: Implement back-face tint on turning page
status: To Do
assignee: []
created_date: '2026-05-08 04:32'
labels: []
milestone: m-15
dependencies:
  - TASK-98
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
When `t >= 0.5` in the `ANIMATING` state, the turning page shows the back face of the incoming page (`sprite_b`, mirrored). Apply a palette darkening via `pal()` before the tline3d draw calls to make the back face slightly darker, simulating paper thickness.

Reset the palette (`pal()`) immediately after the tline3d loop.

The tint intensity should be a small fixed darkening (e.g., shift bright whites toward a mid-grey). Tune visually.

Files to modify: `src/tactics/animation/page_flip_animator.lua`
No unit tests — visual output.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Back face of the turning page is visibly darker than the front face in-game
- [ ] #2 Palette is restored after the tline3d draw loop (no tint bleeds into other draw calls)
- [ ] #3 No Lua errors
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
