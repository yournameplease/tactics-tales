---
id: TASK-102
title: Wire PageFlipAnimator into main.lua draw loop and input gating
status: To Do
assignee: []
created_date: '2026-05-08 04:32'
labels: []
milestone: m-15
dependencies:
  - TASK-97
  - TASK-101
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Integrate `PageFlipAnimator` into the game loop so it ticks, draws, and blocks input correctly.

**`src/tactics/main.lua` — `_draw()`:**
- After `animation_manager:generate_frame_data()`, call `campaign_page_flip_animator():tick()` if available
- Replace `ui_manager:draw(ui_context)` with:
  ```lua
  local flip = -- access animator via game_manager or campaign
  if flip and flip:is_active() then
      flip:draw(ui_manager, ui_context, draw_target_manager)
  else
      ui_manager:draw(ui_context)
  end
  ```

**Access pattern:** Add a helper (e.g., `game_manager:page_flip_animator()`) that returns `campaign.page_flip_animator` when a campaign is active, or `nil` otherwise.

**Input gating:** In the campaign update path (locate the relevant update function), wrap input dispatch with:
  ```lua
  if not campaign.page_flip_animator:is_blocking_input() then
      -- existing input handling
  end
  ```

No unit tests — integration behaviour; verify manually in-game.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Page flip animation plays end-to-end in-game when a new_page node is reached
- [ ] #2 No input is accepted during the 40-frame animation
- [ ] #3 Animation completes and the next page is displayed correctly
- [ ] #4 No frame drops or Lua errors during the animation
- [ ] #5 Existing campaign tests still pass: `make test`
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
