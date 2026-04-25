---
id: TASK-17
title: Create a larger mock map (32x32) for testing
status: To Do
assignee: []
created_date: '2026-04-25 21:35'
labels: []
milestone: m-2
dependencies:
  - TASK-13
priority: medium
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create a 32×32 test map and wire it into the demo story so the larger-map camera behaviour can be exercised manually in-game.

- Author a `map/test_large.map` binary file (32×32 tiles, ground layer filled with a basic tile, no ceiling, minimal spawn points)
- Add a map definition entry in `mods/tt_fantasy_demo_story/game_data/maps.lua`
- Add or modify a battle in the demo story that uses this map

The map only needs to be functional enough to load and scroll — artistic quality is not required.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 The demo story contains a battle that loads the 32x32 map
- [ ] #2 The map loads without errors
- [ ] #3 Camera scrolling can be exercised by moving the cursor to map edges
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
