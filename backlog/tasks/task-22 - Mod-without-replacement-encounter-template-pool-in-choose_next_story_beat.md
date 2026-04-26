---
id: TASK-22
title: 'Mod: without-replacement encounter template pool in choose_next_story_beat'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-4
dependencies: []
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. The choose_next_story_beat hub node reads used_encounter_templates from story memory, excludes already-used templates when selecting the next filler from the archetype's pool, and writes the selected template to memory. When the pool is exhausted, wraps around by resetting the used set. No engine involvement.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 choose_next_story_beat excludes used templates when selecting fillers
- [ ] #2 used_encounter_templates in story memory is updated after each filler selection
- [ ] #3 Pool wraps around when exhausted
- [ ] #4 Beat slots use their fixed template and are unaffected by this logic
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
