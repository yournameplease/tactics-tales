---
id: TASK-8
title: Add CharacterManager query returning full roster including dead units
status: Done
assignee: []
created_date: '2026-04-25 16:02'
updated_date: '2026-04-25 17:09'
labels: []
milestone: m-1
dependencies: []
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a new method to `CharacterManager` that returns all roster characters regardless of `dead` status. The existing `get_player_roster()` filters out dead units (line 68 in `src/tactics/character/character_manager.lua`) — the new method omits that filter.

Files to modify:
- `src/tactics/character/character_manager.lua` — add `get_full_roster(): Character[]` method that maps `player_ids` to characters without filtering by `dead`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 get_full_roster() returns all characters in player_ids order, including those with dead=true.
- [x] #2 get_player_roster() behaviour is unchanged.
- [x] #3 Unit test covers a roster with both living and dead characters.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
