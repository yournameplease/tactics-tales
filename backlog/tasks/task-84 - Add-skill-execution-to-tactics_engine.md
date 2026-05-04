---
id: TASK-84
title: Add skill execution to tactics_engine
status: To Do
assignee: []
created_date: '2026-05-04 22:29'
labels: []
milestone: m-13
dependencies:
  - TASK-80
  - TASK-83
references:
  - docs/adr/skill-system.md
  - src/tactics/battle/tactics/tactics_engine.lua
  - src/tactics/battle/tactics/battle_unit.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `handle_skill(unit, skill_id, target_tile)` to `tactics_engine` (and a coroutine-based `skill_action` helper). Execution order per spec:

1. Deduct `hp_cost` from caster via `caster:take_damage(skill.hp_cost)` — may reduce HP to 0
2. If caster HP = 0, mark for death (do NOT call `kill_unit` yet)
3. Dispatch by `effect_type`:
   - `"heal"`: call `target:restore_hp(skill.heal_amount)` (add this method to BattleUnit, clamps to hp_max)
   - `"damage"`: roll accuracy (`math.random(100) <= skill.accuracy`); if hit, call `target:take_damage(skill.damage)` (true damage — no defense reduction, no counterattack)
4. Process any deaths via existing `kill_unit` path (caster first if dead, then target)
5. Consume resources: set `caster.skill_states[skill_id].cooldown_remaining = skill.cooldown or 0`; if `uses_remaining ~= nil` then decrement
6. Call `finish_unit_action(caster)`

File to modify: `src/tactics/battle/tactics/tactics_engine.lua`
Also add `restore_hp` to `src/tactics/battle/tactics/battle_unit.lua`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Heal effect restores heal_amount HP to target, clamped to hp_max
- [ ] #2 Damage effect applies flat damage with no defense reduction and no counterattack
- [ ] #3 Damage skill can miss when accuracy < 100
- [ ] #4 HP cost is deducted before effect fires
- [ ] #5 Effect fires even if HP cost kills the caster
- [ ] #6 Cooldown and uses_remaining are updated after cast
- [ ] #7 finish_unit_action is called after execution
- [ ] #8 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
