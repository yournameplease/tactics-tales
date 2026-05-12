---
id: TASK-120
title: Update CONTEXT.md with faction-skills domain terms
status: Done
assignee: []
created_date: '2026-05-12 03:08'
updated_date: '2026-05-12 13:20'
labels: []
milestone: m-18
dependencies:
  - TASK-116
  - TASK-118
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update `/mnt/tactics/CONTEXT.md` to reflect the new skill system concepts established during the faction-skills design session.

**Terms to add/update:**
- **Skill** — update definition to reference `effects[]` shape instead of flat `effect_type`
- **SkillEffect** — new term: one step in a skill's execution; has a `type` ("heal", "damage", "hp_cost", "debuff", "buff", etc.) and type-specific fields; skills may have multiple effects applied in sequence
- **SkillStatus** — new term: an active buff or debuff on a BattleUnit; has `kind`, `duration`, and optional magnitude; stored in `active_statuses`, ticked at the start of the affected unit's turn

Depends on TASK-116 and TASK-118 being in place so the terms reflect implemented reality.

**Acceptance Criteria:**
- CONTEXT.md contains entries for SkillEffect and SkillStatus
- Skill entry no longer references `effect_type` as a flat field
- No implementation details (file paths, function names) in the glossary entries
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
