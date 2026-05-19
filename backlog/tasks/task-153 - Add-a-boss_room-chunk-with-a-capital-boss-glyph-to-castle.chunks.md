---
id: TASK-153
title: Add a boss_room chunk with a capital boss glyph to castle.chunks
status: To Do
assignee: []
created_date: '2026-05-19 22:50'
updated_date: '2026-05-19 22:50'
labels: []
milestone: m-23
dependencies:
  - TASK-150
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update `mods/tt_procedural_campaign/game_data/chunks/castle.chunks` to wire up the new boss glyph convention.

The existing `[dead_end_boss]` chunk uses lowercase `g` (which mapped to the wrong role before TASK-150). Update it to use a capital glyph — `G` for tank-boss or `C` for commander-boss — whichever fits the intended enemy composition of that chunk.

Ensure at least one `boss_room`-tagged chunk in the file contains a capital boss glyph so that `kill_boss` maps generated with that objective have a properly tagged boss unit.

Also verify no other existing chunks accidentally contain uppercase letters (which would now be interpreted as boss glyphs).

Depends on TASK-150 (autotiler must recognise uppercase glyphs before chunks can use them).
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
