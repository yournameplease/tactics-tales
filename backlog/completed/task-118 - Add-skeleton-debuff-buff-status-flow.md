---
id: TASK-118
title: Add skeleton debuff/buff status flow
status: Done
assignee: []
created_date: '2026-05-12 03:08'
updated_date: '2026-05-12 12:35'
labels: []
milestone: m-18
dependencies:
  - TASK-116
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement debuff and buff status effects so skills like Wither, Intimidate, Mark Prey, War Cry, Hold the Line, Rally, and Rampage's self-skip-turn can be applied, ticked, and checked.

**SkillEffect types handled:**
- `{type="debuff", kind, duration, self_target?}` — kinds: "skip_turn", "damage_reduction", "move_lock", "mark"
- `{type="buff", kind, duration, self_target?}` — kinds: "double_attack", "defense_bonus", "move_bonus", "extra_action"

`self_target=true` applies the status to the caster instead of the skill's target.

**BattleUnit changes** (`src/tactics/battle/tactics/battle_unit.lua`):
- Add `active_statuses: {kind, duration, ...}[]` initialized to `{}` on spawn
- Add `tick_statuses()` — decrement duration, remove expired; call at start of caster's turn alongside `tick_skill_cooldowns()`

**Engine changes** (`src/tactics/battle/tactics/tactics_engine.lua`):
- In effects iteration: handle "debuff" and "buff" by pushing a status entry onto the resolved target's `active_statuses`
- Add check stubs at relevant sites with TODO notes:
  - Damage calculation: check "damage_reduction" debuff and "defense_bonus" buff
  - Move validation: check "move_lock" debuff and "move_bonus" buff
  - Damage dealt: check "mark" debuff
  - Action granting: check "extra_action" buff
  - Attack: check "double_attack" buff

**Types** (`src/tactics/types/skill_definition.lua`): Add `SkillStatus` type.

Depends on TASK-116.

**Acceptance Criteria:**
- `make test` passes
- Unit with a debuff/buff on `active_statuses` sees it removed after `duration` turns
- Applying a "skip_turn" debuff to a unit sets a status that check stubs can read
- Integration test: applying a debuff via `skill_action` stores it on the target unit
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
