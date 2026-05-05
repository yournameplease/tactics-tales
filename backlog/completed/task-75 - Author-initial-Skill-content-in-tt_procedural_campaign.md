---
id: TASK-75
title: Author initial Skill content in tt_procedural_campaign
status: Done
assignee: []
created_date: '2026-05-04 21:48'
updated_date: '2026-05-05 00:56'
labels: []
milestone: m-13
dependencies:
  - TASK-77
  - TASK-78
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Author sample Skills in `tt_procedural_campaign` (or `tt_fantasy_demo_story`) mod data using the engine schema from the spec. Create `game_data/skills.lua` and declare it in `mod.lua`.

Required skills per spec:
- **heal**: `effect_type = "heal"`, `heal_amount`, `hp_cost`, `cooldown`, targeting excludes full-HP allies
- **fireball** (or similar damaging skill): `effect_type = "damage"`, `damage`, `accuracy`, `uses_per_battle`, adjacent-enemy targeting

Assign at least one skill to at least one character template via `skill_loadout`.

Skills must be purely data — no engine logic.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 At least one heal skill defined in mod data and usable in battle
- [x] #2 At least one damage skill defined in mod data and usable in battle
- [x] #3 Skills are data-only — no skill logic hardcoded in engine
- [x] #4 Mod loads without validation errors
- [x] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
