---
id: TASK-16
title: Implement mouse edge-scroll camera movement
status: Done
assignee: []
created_date: '2026-04-25 21:34'
updated_date: '2026-04-26 00:02'
labels: []
milestone: m-2
dependencies:
  - TASK-13
priority: medium
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
When the mouse cursor is within `CAMERA_EDGE_SCROLL_BORDER` pixels of any viewport edge, scroll the camera by `CAMERA_EDGE_SCROLL_SPEED` pixels per frame in that direction (clamped to map bounds).

This should run each frame during the map panel's `on_update` callback, only when mouse input is active. Check `state.game_context.input_service.current_input == "mouse"` (or equivalent) before applying scroll.

The scroll applies to `battle_context.camera_x` / `battle_context.camera_y` directly (using `clamp_camera` after adjustment).

Find the current mouse position from the input service or Picotron's `mouse()` API, converted to panel-local coordinates.

Files to modify:
- `src/tactics/ui/panels/tactics_map.lua` (on_update callback)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Moving the mouse to within CAMERA_EDGE_SCROLL_BORDER px of the right edge scrolls camera_x right each frame
- [x] #2 Scrolling stops at map boundary
- [x] #3 Edge scroll does not trigger during joypad input
- [x] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
