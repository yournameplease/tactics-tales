---
id: TASK-10
title: Replace MAP_WIDTH/MAP_HEIGHT static config with VIEWPORT_WIDTH/VIEWPORT_HEIGHT
status: To Do
assignee: []
created_date: '2026-04-25 21:33'
labels: []
milestone: m-2
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Remove `MAP_WIDTH` and `MAP_HEIGHT` from `STATIC_CONFIG` in `src/tactics/config.lua`. Add `VIEWPORT_WIDTH = 16` and `VIEWPORT_HEIGHT = 16` in their place. Also add camera-related config constants: `CAMERA_DEAD_ZONE_PLAYER`, `CAMERA_DEAD_ZONE_ENEMY`, `CAMERA_EDGE_SCROLL_BORDER`, `CAMERA_EDGE_SCROLL_SPEED`.

Map dimensions are now properties of `BattleMap` (already `battle_map.width` / `battle_map.height`). The viewport constants describe how many tiles are visible at once.

Files to modify:
- `src/tactics/config.lua`

Any file that currently reads `STATIC_CONFIG.MAP_WIDTH` or `STATIC_CONFIG.MAP_HEIGHT` for viewport/bounds purposes (e.g. `src/tactics/ui/panels/tactics_map.lua`, `src/tactics/battle/battle_menu_manager.lua`) will be updated in subsequent tasks.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 STATIC_CONFIG no longer has MAP_WIDTH or MAP_HEIGHT fields
- [ ] #2 STATIC_CONFIG has VIEWPORT_WIDTH = 16 and VIEWPORT_HEIGHT = 16
- [ ] #3 STATIC_CONFIG has CAMERA_DEAD_ZONE_PLAYER, CAMERA_DEAD_ZONE_ENEMY, CAMERA_EDGE_SCROLL_BORDER, CAMERA_EDGE_SCROLL_SPEED with sensible defaults (2, 6, 20, 2)
- [ ] #4 Project still builds and tests pass (make test)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
