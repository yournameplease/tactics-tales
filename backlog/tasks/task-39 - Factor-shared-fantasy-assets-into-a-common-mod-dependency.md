---
id: TASK-39
title: Factor shared fantasy assets into a common mod dependency
status: To Do
assignee: []
created_date: '2026-04-26 19:12'
labels: []
milestone: m-8
dependencies: []
priority: low
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Identify character templates, items, maps, or lib utilities shared between tt_fantasy_demo_story and tt_fantasy_procedural_story. Move them into a new tt_fantasy_base mod (or equivalent). Both story mods declare it as a dependency. Do not move anything that is story-specific.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Shared assets are identified and moved to a common mod
- [ ] #2 Both story mods load correctly with the new dependency
- [ ] #3 No story-specific content is moved to the shared mod
- [ ] #4 tt_fantasy_demo_story is unaffected functionally
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
