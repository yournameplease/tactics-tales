---
id: TASK-44
title: 'Mod: wire manager nodes into proc story battle loop sequence'
status: To Do
assignee: []
created_date: '2026-04-27 13:41'
labels: []
milestone: m-6
dependencies:
  - TASK-28
  - TASK-29
  - TASK-30
priority: high
ordinal: 3500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update mods/tt_procedural_story/game_data/stories.lua to add the full per-battle loop sequence after archetype_select.

Node sequence per battle iteration:
  1. update_recruitment_quota — accumulate credits, roll pending_recruits
  2. select_faction — pick faction for this battle (already implemented in faction_selection.lua)
  3. run_battle — generate battle config from faction + pending_recruits, play battle
  4. auto_recruit_pending — clear pending_recruits, show debug text

The loop should repeat for each slot in the archetype, then exit the story. The battle_index memory key should be incremented each iteration.

All manager nodes show at least one debug text line (visible to player for debugging).

Files: mods/tt_procedural_story/game_data/stories.lua
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 proc_story runs through all archetype slots in sequence
- [ ] #2 Manager nodes fire in order: quota → faction → battle → auto_recruit each iteration
- [ ] #3 battle_index increments each battle
- [ ] #4 Story exits cleanly after final slot
- [ ] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
