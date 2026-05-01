---
id: TASK-52
title: Deepen BattleObjectiveService — own current_turn and cache objective_text
status: Done
assignee: []
created_date: '2026-05-01 02:34'
updated_date: '2026-05-01 02:54'
labels:
  - architecture
  - battle
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`BattleObjectiveService` was a hollow wrapper: `check_objectives(turn)` and `get_objective_text(turn)` both delegated to condition objects with no retained state. Two callers (`TurnManager` and `BattleUIContext`) each passed `turn_number` on every call, and `BattleUIContext` held a direct service reference solely to recompute display text every tick.

**Decision:** Deepen the service rather than eliminate it. It already owns real policy (defeat-before-victory ordering, `turn_limit_exceeded` abstraction, def-to-runtime conversion) — the fix is to have it also own turn state.

**Approach taken:**
- Added `current_turn` (integer) and `objective_text` (string[]) as fields, computed at construction
- Added `set_turn(n)` which updates `current_turn` and recomputes `objective_text` via a module-local `compute_objective_text`
- `check_objectives()` drops its `turn_number` parameter; uses `self.current_turn`
- `get_objective_text()` removed as a public method; logic is now the internal `compute_objective_text`
- `TurnManager` calls `set_turn()` after incrementing `self.turn` in `advance_turn()`
- `BattleUIContext.enrich()` reads `self.battle_objective_service.objective_text` directly — resolving the pre-existing `-- todo: cache` comment

**Files changed:** `battle_objective_service.lua`, `turn_manager.lua`, `battle_ui_context.lua`, `battle_objective_service_spec.lua`
<!-- SECTION:DESCRIPTION:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented. 802/802 tests pass. The service now owns its turn state and pre-computes display text; callers no longer pass turn on each call.
<!-- SECTION:FINAL_SUMMARY:END -->
