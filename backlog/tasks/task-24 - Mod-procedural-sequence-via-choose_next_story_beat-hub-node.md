---
id: TASK-24
title: 'Mod: procedural sequence via choose_next_story_beat hub node'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-4
dependencies: []
priority: high
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. The choose_next_story_beat node is a factory-function node (already supported by the engine) that reads story_seed + battle_index + archetype_id from story memory, deterministically resolves the next slot (beat or filler, encounter template, faction, map), writes the resolved context to memory, then returns `{type="jump", target=next_node_name}`. This makes the sequence lazy and reproducible without storing it.

Other hub nodes (filler_battle_ending_victory, filler_battle_ending_defeat, beat_ending) route back to choose_next_story_beat and increment battle_index in memory. The finale is detected when battle_index exceeds the archetype's slot count, routing to the ending sequence instead. No engine involvement.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 choose_next_story_beat resolves next slot deterministically from seed + battle_index + archetype
- [ ] #2 Resolved context (template, faction, map) is written to story memory
- [ ] #3 Node returns a jump to the appropriate next node
- [ ] #4 Sequence is identical after save/load (re-derived, never stored)
- [ ] #5 Finale is detected and routes to ending sequence
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
