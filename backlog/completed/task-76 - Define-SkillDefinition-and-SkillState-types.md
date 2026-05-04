---
id: TASK-76
title: Define SkillDefinition and SkillState types
status: Done
assignee: []
created_date: '2026-05-04 22:27'
updated_date: '2026-05-04 22:37'
labels: []
milestone: m-13
dependencies:
  - TASK-73
references:
  - docs/adr/skill-system.md
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add LuaCATS type definitions for the skill data model. Two types are needed:

**SkillDefinition** — the mod-authored data for one skill:
- `name: string`
- `effect_type: "heal" | "damage"`
- `heal_amount?: integer` (heal only)
- `damage?: integer` (damage only)
- `accuracy?: integer` (damage only; 0–100)
- `hp_cost?: integer`
- `cooldown?: integer`
- `uses_per_battle?: integer`
- `targeting: Targeting` (reuses existing weapon Targeting type)

**SkillState** — per-unit battle-instance state for one skill:
- `cooldown_remaining: integer`
- `uses_remaining?: integer` (nil = unlimited)

Place alongside item/weapon types or in a new `src/tactics/skill/` module. No runtime logic — types only.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 SkillDefinition and SkillState LuaCATS types are defined
- [x] #2 make test passes with no new type errors
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
