---
id: TASK-12
title: Drive camera from cursor movement and enemy turn events
status: To Do
assignee: []
created_date: '2026-04-25 21:34'
labels: []
milestone: m-2
dependencies:
  - TASK-11
priority: high
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Wire the camera into the game loop so it tracks the cursor and enemy actions.

**Player turn:** After `hovered_point` changes in `BattleUIContext`, call `move_camera` with `CAMERA_DEAD_ZONE_PLAYER`.

**Enemy turn:** When the enemy AI begins an action (the point where the engine announces which unit is acting), call `move_camera` with `CAMERA_DEAD_ZONE_ENEMY` targeting that unit's tile. Identify the correct hook/callback in `src/tactics/battle/tactics/tactics_engine.lua` or the AI layer.

Files to modify:
- `src/tactics/battle/battle_ui_context.lua` (or wherever `hovered_point` is updated)
- `src/tactics/battle/tactics/tactics_engine.lua` (enemy action trigger)

Identify the exact update site by searching for where `hovered_point` is assigned and where enemy unit actions are dispatched.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Moving the cursor near a viewport edge causes camera_x/camera_y to update
- [ ] #2 When an enemy begins its action the camera jumps to center within CAMERA_DEAD_ZONE_ENEMY tiles of that unit
- [ ] #3 Camera never exceeds map bounds
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
