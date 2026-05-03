---
id: TASK-62
title: Add base/lib/character.lua — character template option helpers
status: Done
assignee: []
created_date: '2026-05-03 19:24'
updated_date: '2026-05-03 19:27'
labels: []
milestone: m-12
dependencies: []
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Both `tt_fantasy_demo_story/game_data/characters.lua` and `test_base/game_data/characters.lua` define identical `options.list()` and `options.weighted()` local functions. Extract these into `base/lib/character.lua` and expose them as `lib.libs.character.options.list()` / `lib.libs.character.options.weighted()`. Remove the local copies from both mods.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 base/lib/character.lua exists and is registered in the mod sandbox
- [x] #2 lib.libs.character.options.list() and options.weighted() match the existing signatures
- [x] #3 Local copies removed from tt_fantasy_demo_story and test_base characters.lua
- [x] #4 Tests pass
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
