---
id: TASK-116
title: 'Migrate SkillDefinition to effects[] shape'
status: Done
assignee: []
created_date: '2026-05-12 03:07'
updated_date: '2026-05-12 03:29'
labels: []
milestone: m-18
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the flat `effect_type`/`heal_amount`/`damage`/`accuracy`/`hp_cost` fields on `SkillDefinition` with an `effects: SkillEffect[]` array. This is the foundation for compound skills (e.g. Rampage = AoE damage + self-debuff) and the full faction-skills roster.

**Agreed shape:**
```
SkillEffect { type, amount?, damage?, accuracy?, kind?, duration?, self_target? }
SkillDefinition { name, cooldown?, uses_per_battle?, targeting, effects[] }
```
`effect_type` values: "heal" | "damage" | "hp_cost" | "debuff" | "buff" | "spawn" | "transfer_hp" | "drain_heal" | "siphon"

**Files:**
- `src/tactics/types/skill_definition.lua` — replace SkillDefinition; add SkillEffect type
- `src/tactics/mods/mod_schema.lua` — replace flat effect_type validation with effects[] validation
- `src/tactics/battle/tactics/tactics_engine.lua` — update `skill_action` to iterate effects[]; handle "heal", "damage", "hp_cost" cases
- `src/tactics/battle/battle_menu_manager.lua` — update availability check to read hp_cost from effects[]
- `mods/tt_procedural_campaign/game_data/skills.lua` — migrate `heal` and `missile` to new shape
- `src/integration/battle/tactics_engine_spec.lua` — migrate test fixtures to new shape

**Acceptance Criteria:**
- `make test` passes with no regressions
- `heal` and `missile` use `effects[]`
- mod_schema rejects a skill missing `effects`
- mod_schema rejects an effect with an unknown `type`
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
