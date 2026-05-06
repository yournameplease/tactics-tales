---
id: TASK-86
title: Test AI engine through real BattleMap and pathfinding
status: Done
assignee: []
created_date: '2026-05-05 13:19'
updated_date: '2026-05-06 02:54'
labels: []
milestone: m-14
dependencies: []
references:
  - src/spec/battle/tactics/ai_engine_spec.lua
  - src/tactics/battle/tactics/ai_engine.lua
  - src/tactics/battle/pathfinding.lua
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The AI engine spec uses a hardcoded fake map (`make_map()` with static terrain) and verifies that handler methods are called rather than that the AI makes correct decisions. The seam between AI and BattleMap is replaced by a stub with different invariants, so pathfinding–AI interaction bugs are invisible.

Replace the fake map with a real (or minimally-real) `BattleMap` and `pathfinding` module. Small maps (3×4 tiles) are sufficient. Tests should verify the unit the AI targets and the tile it moves to, not just which handler method name was invoked.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Tests use a real BattleMap (or a minimal faithful wrapper) rather than a hand-rolled stub
- [x] #2 At least one test verifies the tile the AI moves to, not just the handler method name
- [x] #3 At least one test exercises terrain cost influencing path choice (e.g. two routes of different cost)
- [x] #4 At least one test covers the case where a preferred path is blocked by another unit
- [x] #5 Existing passing tests remain green
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced the hand-rolled BattleMap stub in ai_engine_spec.lua with the real `battle_map.new` + `spawn_unit` + `userdata` layer setup. Added `make_battle_map` helper that builds a genuine BattleMap with configurable per-tile terrain sprites (sprite 1 = normal cost 1, sprite 2 = mountain cost 4 via fset).

Added two new tests:
- **Terrain routing**: 5×2 map with mountain at (1,0) forces the AI to detour via row 1, verifying it stops at (1,1) instead of the direct row-0 path.
- **Ally blocker**: 3×2 map with an ally at (1,0) blocks the only affordable melee position; the AI back-tracks to its starting tile and waits.

All 965 tests pass.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
