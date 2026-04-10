# Battle System Migration: Test Coverage Decisions

Decisions for the remaining unmigrated battle files, covering whether and how to unit-test each during the Teal→Lua migration.

---

## `battle_objective_service.tl` — Unit test ✓

**What it does:** Iterates victory/failure conditions, checks them against the current map state, and returns a `BattleFinishState`. Also builds the objective text list for the UI.

**Decision: write unit tests, but migrate `objective.tl` first.**

`new()` calls `lists.map(battle_objective_definition.to_victory_condition)` to convert definition objects into runtime condition objects. Using real conditions (from `objective.tl`) is preferred over mocks — it keeps the test honest and avoids creating a test-only abstraction.

**Migration order:** `objective.tl` → `battle_objective_service.tl`

**What to test:**
- Failure conditions are checked *before* victory conditions (a loss on the same turn as a win is a loss)
- When a failure condition triggers, `check_objectives` returns `{ finished=true, command="BATTLE_END_DEFEAT" }`
- When a victory condition triggers, returns `{ finished=true, command="BATTLE_END_VICTORY" }`
- When nothing triggers, returns `{ finished=false }`
- Turn limit exceeded is passed to condition `check()` and can trigger failure
- `get_objective_text` returns condition text strings, with turn counter inserted at position 1 when a turn limit is set, and later entries prefixed with `"or "`
- `get_objective_text` with no turn limit omits the turn counter entry

**Mock surface:** A minimal mock BattleMap is sufficient (conditions in `objective.tl` inspect unit sides and tags).

---

## `ai_engine.tl` — Unit test ✓

**What it does:** `compute_unit_ai` runs pathfinding, evaluates combat previews for reachable targets, picks the best action (attack, deep-move, or wait), and dispatches to `tactics_engine`. `handle_one_unit_action` wraps a single unit's turn in a TaskManager coroutine.

**Decision: write unit tests for `compute_unit_ai`; skip `handle_one_unit_action`.**

`compute_unit_ai` has three testable decision branches and a non-trivial scoring function (`better_shallow_movement_option`). Using real pathfinding and real `combat_calculator` (both already migrated) keeps the tests grounded. Only BattleMap and TacticsEngine need mocking.

`handle_one_unit_action` wraps the whole thing in a coroutine with `pt.yield` and `is_blocked` polling — not worth unit testing; integration tests cover it.

**What to test:**
- When a target is reachable and attackable in one move, `tactics_engine:handle_move_and_attack` is called with the correct unit, destination, path, and target
- When no target is reachable in one move but targets exist elsewhere, `tactics_engine:handle_move_and_wait` is called with a destination closer to the nearest target
- When no targets exist at all, `tactics_engine:handle_move_and_wait` is called with the unit's current tile (wait in place)
- AI prefers a kill over a non-kill (`expected_kill` is primary sort key)
- AI avoids a self-kill over lower damage (`expected_self_kill` is next sort key)
- AI prefers no counterattack over counterattack (`expected_counterattack` is next sort key)
- AI prefers higher expected damage as tiebreaker
- `ai.move = "zero"` prevents movement (max_move and shallow_move_limit both 0)

**Mock surface:**
- `BattleMap`: `get_units`, `tile_is_legal_destination`, `tile_is_in_map`, `get_at_tile`, plus an `AllTileCosts` userdata-like structure or stub that `pathfinding.calculate_all_tile_costs` can use
- `TacticsEngine`: spy table capturing which method was called and with which arguments
- `TaskManager`: not needed (testing `compute_unit_ai` directly, not `handle_one_unit_action`)

**Note on mock complexity:** The BattleMap mock needs to satisfy `calculate_all_tile_costs` (which walks terrain) and `foreachpoint`. Consider using a small real map rather than a hand-rolled stub, or building a minimal tile-cost table if the pathfinding mock surface is too large.

---

## `tactics_engine.tl` — Integration tests only ✗

**What it does:** 897 lines. Core battle engine with 28+ public methods spanning unit spawning, movement, combat, dialogue, animation sequencing, and tile validity caching. Manages `tactics_locks`, `battle_is_blocked`, dialogue state, and valid-tile caches as mutable state.

**Decision: no unit tests during migration.**

The module is deeply entangled with:
- `TaskManager` coroutines (every action is `start_routine` + yield sequences)
- `AnimationManager` (frame-by-frame animation data)
- `EventBus` / `EventWriter` (emits and listens to events)
- `DialogueManager` (dialogue playback)
- `MusicPlayer`

There is no practical way to test any meaningful behaviour without the full runtime. The migration will be verified by:
1. Running `make ut` to confirm no regressions in existing tests
2. Running the game itself (manual integration check)
3. Future integration test harness when one is established

---

## `battle_manager.tl` — Integration tests only ✗

**What it does:** 178 lines. Pure orchestrator — `new()` constructs and wires together 8 subsystems (TacticsEngine, AIEngine, TurnManager, BattleMenuManager, BattleObjectiveService, ScriptManager, UIContextManager, MusicPlayer). `update()` and `teardown()` are trivial one-line delegators.

**Decision: no unit tests during migration.**

There is no internal logic to test — it is entirely wiring. Any test would be a construction test that instantiates the full battle stack, which is an integration test by nature. Verified the same way as `tactics_engine`.

---

## Summary Table

| File | Lines | Unit tests? | Notes |
|------|-------|-------------|-------|
| `objective.tl` | 144 | Yes (prerequisite) | Migrate first; provides real conditions for objective service tests |
| `battle_objective_service.tl` | 99 | Yes | After `objective.tl`; test check logic, text generation, turn limit |
| `ai_engine.tl` | 259 | Yes (partial) | Test `compute_unit_ai` decision branches; skip `handle_one_unit_action` |
| `tactics_engine.tl` | 897 | No | Integration only — full runtime dependencies |
| `battle_manager.tl` | 178 | No | Integration only — pure wiring, no internal logic |
