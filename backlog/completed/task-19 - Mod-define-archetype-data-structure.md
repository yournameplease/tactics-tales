---
id: TASK-19
title: 'Mod: define archetype data structure'
status: Done
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 22:42'
labels: []
milestone: m-3
dependencies: []
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Design the archetype data table shape in the mod. Archetypes are a mod-level concept; the engine does not need to know about them. An archetype includes: ordered slot sequence (each slot tagged beat or filler), filler pool with weights, optional per-slot pool overrides, recruitment rate, and display metadata (name, description used by the selection node). Document with a worked example in test data.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Archetype table shape is defined and documented
- [x] #2 Slots are ordered and tagged beat or filler
- [x] #3 Filler pool weights declared at archetype level with optional per-slot overrides
- [x] #4 Recruitment rate is configurable per archetype
- [x] #5 A worked example archetype exists in test_base or a new test mod
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
