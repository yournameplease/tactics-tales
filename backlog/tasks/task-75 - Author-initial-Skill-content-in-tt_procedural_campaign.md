---
id: TASK-75
title: Author initial Skill content in tt_procedural_campaign
status: To Do
assignee: []
created_date: '2026-05-04 21:48'
labels: []
milestone: m-13
dependencies:
  - TASK-73
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Author sample Skills in tt_procedural_campaign mod data using the engine schema from TASK-73/74. These are sample content — not fixed requirements. Initial candidates: a healing skill (separate action, adjacent ally, no Combat exchange) and a damaging skill (initiates Combat exchange, no counterattack, true damage). Exact skills subject to change based on playtesting.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 At least one healing Skill defined in mod data and usable in battle
- [ ] #2 At least one damaging Skill defined in mod data and usable in battle
- [ ] #3 Skills are data-only — no skill logic hardcoded in engine
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
