---
id: TASK-117
title: Add skill builder library
status: Done
assignee: []
created_date: '2026-05-12 03:08'
updated_date: '2026-05-12 03:36'
labels: []
milestone: m-18
dependencies:
  - TASK-116
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create `src/tactics/skills/builders.lua` with reusable targeting helpers and skill definition factories. All mod skill files should import from this rather than defining local helpers.

**Targeting helpers** (extend existing patterns from `mods/tt_procedural_campaign/game_data/skills.lua`):
- `self_target()` — caster's own tile; no player selection
- `ally_in_range(min, max, filter?)` — single ally target
- `enemy_in_range(min, max)` — single enemy target
- `adjacent_allies()` — all adjacent ally tiles (for AoE heals, formation skills)
- `adjacent_enemies()` — all adjacent enemy tiles (for Rampage)
- `allies_in_range(min, max)` — all allies in range (for Mass Heal)

**Skill factories** (return a complete SkillDefinition table using the effects[] shape from TASK-116):
- `make_heal(name, amount, targeting, opts)` — `opts: {cooldown, uses_per_battle, hp_cost}`
- `make_damage(name, damage, accuracy, targeting, opts)`
- `make_debuff(name, kind, duration, targeting, opts)`
- `make_buff(name, kind, duration, targeting, opts)`

**Files:**
- `src/tactics/skills/builders.lua` — new file (create `src/tactics/skills/` directory)
- `mods/tt_procedural_campaign/game_data/skills.lua` — replace local helper definitions with imports from builders

Depends on TASK-116 (effects[] shape must be in place first).

**Acceptance Criteria:**
- `make test` passes
- No local targeting helper functions remain in `mods/tt_procedural_campaign/game_data/skills.lua`
- `builders.lua` has LuaCATS annotations on all public functions
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
