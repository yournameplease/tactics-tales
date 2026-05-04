---
id: TASK-34
title: 'Mod: configurable recruitment rate overrides per archetype and difficulty'
status: To Do
assignee: []
created_date: '2026-04-26 19:12'
updated_date: '2026-05-04 21:47'
labels:
  - deferred
milestone: m-7
dependencies: []
priority: low
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. The archetype data table declares an optional recruitment_rate and optional per-difficulty rate adjustments. The hub node's post-battle quota accumulation logic reads these from the archetype data (via story memory or mod Lua globals) and applies the appropriate rate. Default rate is used when no override is specified.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Archetypes can declare a recruitment_rate override
- [ ] #2 Archetypes can declare per-difficulty recruitment_rate adjustments
- [ ] #3 Default rate (~1.5) is used when no override is specified
- [ ] #4 Rate is applied during post-battle quota accumulation in story memory
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
