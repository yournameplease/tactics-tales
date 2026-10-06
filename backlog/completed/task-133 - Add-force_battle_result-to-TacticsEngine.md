---
id: TASK-133
title: Add force_battle_result to TacticsEngine
status: Done
assignee: []
created_date: '2026-05-16 19:52'
updated_date: '2026-05-16 20:03'
labels: []
milestone: m-20
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a `force_battle_result(result)` method to `TacticsEngine` that immediately emits a `BATTLE_END` event, bypassing the normal objective-check loop.\n\nFile to modify:\n- `src/tactics/battle/tactics/tactics_engine.lua` — add the method; it should call `self.event_writer:emit(\"BATTLE_END\", { result = result })` where `result` is `\"VICTORY\"` or `\"DEFEAT\"`\n\nLook at how `TurnManager:check_objectives()` emits `BATTLE_END` in `src/tactics/battle/turn_manager.lua` to match the exact event payload shape.\n\nAcceptance criteria:\n- `TacticsEngine` has a `force_battle_result(result)` method\n- Calling it emits `BATTLE_END` with the correct payload shape (matching what `TurnManager:check_objectives` emits)\n- LuaCATS annotation documents `result` as `BattleEndResult`
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
