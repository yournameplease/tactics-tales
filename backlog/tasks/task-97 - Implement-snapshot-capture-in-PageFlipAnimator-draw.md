---
id: TASK-97
title: 'Implement snapshot capture in PageFlipAnimator:draw()'
status: To Do
assignee: []
created_date: '2026-05-08 04:32'
labels: []
milestone: m-15
dependencies:
  - TASK-96
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the two-frame snapshot sequence inside `PageFlipAnimator:draw(ui_manager, ui_context, draw_target_manager)`.

**PENDING_BEFORE frame:**
1. `draw_target_manager:push_target(screen_w, screen_h, 0, 0)`
2. `ui_manager:draw(ui_context)` — renders current page into the target
3. `self.sprite_a = draw_target_manager:pop_sprite()`
4. Fire `self.callback()` — this calls `clear_page()` + `advance_node()` on the campaign
5. Transition to `PENDING_AFTER`

**PENDING_AFTER frame:**
1. `ui_manager:calculate(ui_context)` — recompute layout for new page content
2. `draw_target_manager:push_target(screen_w, screen_h, 0, 0)`
3. `ui_manager:draw(ui_context)` — renders new page into the target
4. `self.sprite_b = draw_target_manager:pop_sprite()`
5. `self.frame = 0`; transition to `ANIMATING`

Screen dimensions are available via Picotron's `screen_width()` / `screen_height()` (or a stored constant).

Files to modify: `src/tactics/animation/page_flip_animator.lua`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 In PENDING_BEFORE: sprite_a is set and callback is called before transitioning
- [ ] #2 In PENDING_AFTER: sprite_b is set and state transitions to ANIMATING
- [ ] #3 Callback fires exactly once between the two snapshots
- [ ] #4 draw_target_manager push/pop is balanced (no leaked targets)
- [ ] #5 `make test` passes with mocked ui_manager and draw_target_manager
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
