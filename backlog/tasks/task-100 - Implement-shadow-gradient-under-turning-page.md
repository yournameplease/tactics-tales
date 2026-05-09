---
id: TASK-100
title: Implement shadow gradient under turning page
status: To Do
assignee: []
created_date: '2026-05-08 04:32'
labels: []
milestone: m-15
dependencies:
  - TASK-98
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Before drawing the turning page columns, draw a soft shadow on the static destination page beneath the sweep area.

**Shadow geometry:**
- Shadow width = `visible_w` (matches the projected width of the turning page)
- Shadow is positioned on the destination side of the spine (right half when `t < 0.5`, left half when `t >= 0.5`)
- Draw 4–6 vertical gradient rects of increasing transparency using `rectfill` with palette-shifted dark colours, fading from the spine edge outward
- Shadow alpha/opacity is proportional to `math.sin(t * math.pi)` (peaks at midpoint, zero at start/end)

Files to modify: `src/tactics/animation/page_flip_animator.lua`
No unit tests — visual output.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A visible shadow appears on the destination page beneath the turning page in-game
- [ ] #2 Shadow fades in and out across the animation (absent at t=0 and t=1)
- [ ] #3 Shadow does not extend beyond the destination page half
- [ ] #4 No Lua errors
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
