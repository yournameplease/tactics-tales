---
id: TASK-63
title: Add base/lib/map.lua — static map definition factory
status: Done
assignee: []
created_date: '2026-05-03 19:24'
updated_date: '2026-05-03 19:34'
labels: []
milestone: m-12
dependencies: []
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`static_map(file)` is independently defined in `tt_fantasy_demo_story/game_data/maps.lua`, `tt_procedural_campaign/game_data/maps.lua`, and `test_base/game_data/maps.lua`. The three versions have already diverged in style. Extract into `base/lib/map.lua` as `lib.libs.map.static(file)`. Co-locating the factory with the schema shape means a new required field on static maps only needs one change.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 base/lib/map.lua exists and is registered in the mod sandbox
- [x] #2 lib.libs.map.static(file) returns correct map definition shape
- [x] #3 All three mods use lib.libs.map.static() and remove their local copies
- [x] #4 Tests pass
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
