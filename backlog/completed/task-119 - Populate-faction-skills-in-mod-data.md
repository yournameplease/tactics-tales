---
id: TASK-119
title: Populate faction skills in mod data
status: Done
assignee: []
created_date: '2026-05-12 03:08'
updated_date: '2026-05-12 12:47'
labels: []
milestone: m-18
dependencies:
  - TASK-117
  - TASK-118
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add all faction skills from `docs/specs/faction-skills-spec.md` to `mods/tt_procedural_campaign/game_data/skills.lua` using the builder library (TASK-117). Deferred skills get commented stubs.

**Implementable now (heal/damage/debuff/buff effects):**

Cultists:
- `soul_strike` — `[{hp_cost,1}, {damage,3,acc=100}]`, enemy range 1–2

Bandits:
- `ritual_healing` — `[{heal,3}]`, self_target(), shaman-only
- `intimidate` — `[{debuff, move_lock, dur=1}]`, enemy 1–2, cd 3
- `mark_prey` — `[{debuff, mark, amount=1, dur=1}]`, enemy 1–2, cd 3
- `war_cry` — `[{buff, double_attack, dur=1}]`, self_target(), 1/battle
- `rampage` — `[{damage,3,acc=100}, {debuff,skip_turn,dur=1,self_target=true}]`, adjacent_enemies(), 1/battle

Militia:
- `militia_heal` — `[{heal,4}]`, ally range 1, cd 3, cleric-only
- `field_healing` — `[{heal,1}]`, adjacent_allies(), cd 3, cleric-only
- `mass_heal` — `[{heal,2}]`, allies_in_range(1,2), 1/battle, cleric-only
- `hold_the_line` — `[{buff,defense_bonus,amount=1,dur=1}]`, adjacent_allies(), cd 3
- `rally` — `[{buff,extra_action,dur=1}]`, ally range 1, cd 2, 1/battle, commander-only
- `advance_formation` — `[{buff,move_bonus,amount=1,dur=1}]`, adjacent_allies(), commander-only
- `wither` — `[{debuff,damage_reduction,amount=1,dur=2}]`, enemy 1–2, cd 2

**Deferred stubs (effect types not yet in engine):**
- `share_life`, `sacrifice`, `raise_soldier`, `blood_siphon`, `blood_ritual` — stubs with `-- TODO` comment and a placeholder `effects=[]`

**Files:**
- `mods/tt_procedural_campaign/game_data/skills.lua`

Depends on TASK-117 (builders) and TASK-118 (debuff/buff skeleton).

**Acceptance Criteria:**
- `make test` passes
- All implementable skills load without mod_schema validation errors
- Deferred skills present as stubs and do not crash on load
- Each skill key matches the name used in character template `skill_loadout` entries in `mods/tt_procedural_campaign/game_data/characters.lua`
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
