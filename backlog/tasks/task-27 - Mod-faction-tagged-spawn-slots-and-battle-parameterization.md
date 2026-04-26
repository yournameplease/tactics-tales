---
id: TASK-27
title: 'Mod: faction-tagged spawn slots and battle parameterization'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-5
dependencies: []
priority: high
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. Battle factories already receive StoryConfig. Encounter templates declare unit spawn points using faction tag names (e.g. "enemy_infantry") instead of hardcoded character templates. The battle factory reads faction_id from story memory, looks up the faction's tag-to-template mapping, and resolves character templates. faction_id is also readable by battle scripts from story memory for dialogue or behavior branching. Existing static battles are unaffected.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Encounter templates use faction tag names for enemy spawn slots
- [ ] #2 Battle factory reads faction_id from story memory and resolves tags to templates
- [ ] #3 faction_id is accessible in battle scripts via story memory
- [ ] #4 Existing static battles are unaffected
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
