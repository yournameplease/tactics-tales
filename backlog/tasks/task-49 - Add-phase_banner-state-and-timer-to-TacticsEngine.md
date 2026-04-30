---
id: TASK-49
title: Add phase_banner state and timer to TacticsEngine
status: To Do
assignee: []
created_date: '2026-04-30 03:19'
labels: []
milestone: m-10
dependencies:
  - TASK-48
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a `phase_banner` field to `TacticsEngine` in `src/tactics/battle/tactics/tactics_engine.lua`. This field holds `{text: string, frames_remaining: integer}` while a banner is active, or `nil` otherwise.

Key changes:
- Add `phase_banner` to the `TacticsEngine` LuaCATS class annotation (type: `{text: string, frames_remaining: integer}?`)
- Add a `show_phase_banner(text)` method that sets `phase_banner` and `battle_is_blocked = true`
- In `TacticsEngine:update()`, decrement `phase_banner.frames_remaining` each frame; when it reaches 0, set `phase_banner = nil` and `battle_is_blocked = false`
- `is_blocked()` already returns true when `battle_is_blocked` is set, so no changes needed there

Depends on task-48 for `STATIC_CONFIG.PHASE_BANNER_DURATION`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 show_phase_banner(text) sets phase_banner and battle_is_blocked = true
- [ ] #2 update() decrements frames_remaining each frame and clears phase_banner + battle_is_blocked when it reaches 0
- [ ] #3 is_blocked() returns true while phase_banner is active (via battle_is_blocked)
- [ ] #4 phase_banner is nil on construction
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
