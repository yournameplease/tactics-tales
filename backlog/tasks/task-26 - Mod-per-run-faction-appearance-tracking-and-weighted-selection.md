---
id: TASK-26
title: 'Mod: per-run faction appearance tracking and weighted selection'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-5
dependencies: []
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. faction_appearance_counts lives in story memory. The choose_next_story_beat hub node reads counts, applies the archetype's bias (prefer_novel weights under-used factions higher; prefer_dominant weights over-used factions higher), selects a faction using the story-level RNG instance from StoryConfig, then writes the selected faction_id and updated counts to memory. Selection remains probabilistic. No engine involvement.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 faction_appearance_counts in story memory is updated after each battle
- [ ] #2 Faction selection uses appearance counts to adjust weights via story RNG instance
- [ ] #3 Archetypes declare prefer_novel or prefer_dominant bias
- [ ] #4 Selection remains probabilistic (no hard guarantees)
- [ ] #5 Selected faction_id is written to story memory for use by the battle factory
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
