---
id: TASK-86
title: Test AI engine through real BattleMap and pathfinding
status: To Do
assignee: []
created_date: '2026-05-05 13:19'
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
- [ ] #1 Tests use a real BattleMap (or a minimal faithful wrapper) rather than a hand-rolled stub
- [ ] #2 At least one test verifies the tile the AI moves to, not just the handler method name
- [ ] #3 At least one test exercises terrain cost influencing path choice (e.g. two routes of different cost)
- [ ] #4 At least one test covers the case where a preferred path is blocked by another unit
- [ ] #5 Existing passing tests remain green
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
