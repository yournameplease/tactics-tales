---
id: TASK-51
title: Render phase banner in tactics_map panel
status: To Do
assignee: []
created_date: '2026-04-30 03:20'
labels: []
milestone: m-10
dependencies:
  - TASK-49
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Draw the phase banner overlay in `src/tactics/ui/panels/tactics_map.lua` inside `draw_tactics_map`, after all other map drawing is complete.

Read `state.battle_context.tactics_engine.phase_banner` (type: `{text: string, frames_remaining: integer}?`). When non-nil, draw a centered filled rectangle with white text over the map.

Minimal placeholder implementation — no fade, no per-side colors, no border. Those are polish for a later pass.

Example rendering (exact coordinates to be tuned by feel):
```lua
local banner = state.battle_context.tactics_engine.phase_banner
if banner then
    local sw = STATIC_CONFIG.SCREEN_WIDTH
    local sh = STATIC_CONFIG.SCREEN_HEIGHT
    local bw, bh = 160, 24
    local bx = (sw - bw) / 2
    local by = (sh - bh) / 2
    rectfill(bx, by, bx + bw, by + bh, 0)  -- black background
    print(banner.text, bx + 8, by + 8, 7)  -- white text
end
```

Depends on task-49 for the `phase_banner` field on `TacticsEngine`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Banner text is visible centered on screen when phase_banner is non-nil
- [ ] #2 No banner is drawn when phase_banner is nil
- [ ] #3 Banner renders after all other map drawing (appears on top)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
