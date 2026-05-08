---
id: TASK-98
title: Implement tline3d curl geometry
status: To Do
assignee: []
created_date: '2026-05-08 04:32'
labels: []
milestone: m-15
dependencies:
  - TASK-97
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the per-frame curl rendering in `PageFlipAnimator:draw()` during the `ANIMATING` state.

**Geometry per frame:**
- `t = smoothstep(self.frame / 40)`
- `half_w = screen_w / 2`
- `visible_w = half_w * math.abs(math.cos(t * math.pi))`
- The turning page sweeps from the right side toward the spine (forward) or left toward spine (backward)
- Vertical curl displacement per column: `disp = amplitude * math.sin(t * math.pi) * (col_offset / half_w)` where `amplitude` ≈ 8px and `col_offset` is distance from the leading edge
- Source sprite: `sprite_a` when `t < 0.5` (front face), `sprite_b` when `t >= 0.5` (back face, U coords mirrored)

**Drawing:**
1. Blit `sprite_a` left half as static background (left page, unchanged)
2. Blit `sprite_b` right half as static background (destination page, already visible)
3. For each screen column `x` in the turning page's current visible range: `tline3d(src_ud, x, y0 + disp, x, y1 + disp, u, 0, u, screen_h, 1, 1)`

Files to modify: `src/tactics/animation/page_flip_animator.lua`
No unit tests — visual output; verify in-game.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Page curl is visible in-game during a campaign new_page transition (after wiring tasks are done)
- [ ] #2 The turning page narrows to a line at the midpoint (t=0.5) then expands on the opposite side
- [ ] #3 Curl animation completes in exactly 40 frames
- [ ] #4 No Lua errors during animation
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
