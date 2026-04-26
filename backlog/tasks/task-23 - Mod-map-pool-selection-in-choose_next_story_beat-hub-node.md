---
id: TASK-23
title: 'Mod: map pool selection in choose_next_story_beat hub node'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-4
dependencies: []
priority: medium
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. Encounter templates (beat and filler) declare a pool of eligible map IDs. The choose_next_story_beat hub node selects a map from the pool using the battle-level RNG instance from StoryConfig and writes the selected map_id to story memory for the upcoming battle. Single-element pools serve as fixed maps for beats. No engine involvement.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Encounter templates declare a maps pool (list of map IDs, optionally weighted)
- [ ] #2 choose_next_story_beat selects a map using the battle-level RNG instance
- [ ] #3 Selected map_id is written to story memory and consumed by the battle factory
- [ ] #4 Single-element pools work correctly for fixed-map beats
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
