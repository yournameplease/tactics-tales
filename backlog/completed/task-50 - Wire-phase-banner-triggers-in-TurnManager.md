---
id: TASK-50
title: Wire phase banner triggers in TurnManager
status: Done
assignee: []
created_date: '2026-04-30 03:20'
updated_date: '2026-04-30 03:27'
labels: []
milestone: m-10
dependencies:
  - TASK-49
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Call `tactics_engine:show_phase_banner(text)` at every non-skipped phase transition in `src/tactics/turn_manager.lua`, and yield in the coroutine until the banner clears.

The banner text format is `"Turn N: Player Phase"`, `"Turn N: Enemy Phase"`, or `"Turn N: Ally Phase"` (neutral side maps to "Ally").

Key changes:

1. **`advance_phase()`** — after `self.phase` is set and before the AI or player menu activates, call `self.tactics_engine:show_phase_banner(text)` then yield while `self.tactics_engine.phase_banner ~= nil`. This already runs inside a `task_manager:start_routine` coroutine.

2. **`TACTICS_BEGIN_BATTLE` handler** — currently sets the menu synchronously. Wrap the handler body in `task_manager:start_routine` so it can yield. Show the banner before calling `self.battle_menu_manager:set_menu("MENU_PLAYER_TURN")`. This fires after deployment is confirmed (or immediately for non-deployment battles), which is the correct moment for the Turn 1 Player Phase banner.

Helper to build the text string:
```lua
local SIDE_LABEL = { player = "Player", enemy = "Enemy", neutral = "Ally" }
local function phase_banner_text(turn, side)
    return "Turn " .. turn .. ": " .. SIDE_LABEL[side] .. " Phase"
end
```

Depends on task-49 for `show_phase_banner`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Banner fires on every non-skipped phase in advance_phase(), including enemy and ally phases
- [ ] #2 Banner fires for Turn 1 Player Phase after TACTICS_BEGIN_BATTLE (post-deployment or immediate)
- [ ] #3 Banner does not fire for phases that are skipped due to no units on that side
- [ ] #4 Neutral side displays as 'Ally' in the banner text
- [ ] #5 Battle input is blocked while banner is showing
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
