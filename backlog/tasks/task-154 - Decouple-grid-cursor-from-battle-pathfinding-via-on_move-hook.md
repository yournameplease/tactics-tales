---
id: TASK-154
title: Decouple grid cursor from battle pathfinding via on_move hook
status: Done
assignee: []
created_date: '2026-05-22 23:36'
updated_date: '2026-05-23 00:18'
labels: []
milestone: m-24
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`src/tactics/menu/cursor/nested/grid.lua` is otherwise domain-neutral but currently `require`s `src.tactics.battle.pathfinding` (line 13) and `src.tactics.constants` for `HIGHLIGHT` (line 5). The coupling is narrow: on cursor move, when the new tile is flagged `IS_VALID`, it extends a path via `pathfinding.extend_path_to_point` (lines 143-145).

Refactor so the grid cursor takes an optional `on_move` hook (and any other injection points the call sites demand, such as `on_anchor_change` — see the `path_anchor` setter near line 455). The battle's menu wiring then supplies a closure that does the pathfinding/HIGHLIGHT check.

After the refactor, grepping the proposed-engine set should show no references to `HIGHLIGHT`, `pathfinding`, or anything under `src/tactics/battle/`, `src/tactics/campaign/`, or `src/tactics/game/`.

If `self.path`, `self.legal_tiles`, `self.max_path_length`, or `self.path_anchor` are only used by the hook, push them off the cursor type and onto the hook's closure / a game-owned wrapper. If engine code (e.g. rendering) still needs `self.path`, keep it as an opaque field the engine doesn't introspect.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 grid.lua has no require of src.tactics.battle.* or src.tactics.constants
- [x] #2 Battle screens using the grid cursor still extend paths correctly when moving over IS_VALID tiles
- [x] #3 Existing tests for grid cursor and any affected battle UI flows pass
- [x] #4 Hook surface is minimal — no speculative callbacks added beyond what current call sites need
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Replaced grid cursor's hardcoded pathfinding/HIGHLIGHT logic with a generic on_move hook.

- Removed `require` of `src.tactics.constants` and `src.tactics.battle.pathfinding` from `src/tactics/menu/cursor/nested/grid.lua`.
- Dropped `with_path_anchor` / `with_path_length` / `max_path_length` / `get_path_anchor` from the grid's API and class.
- Added `with_on_move(make_on_move)`: a factory invoked at `to_cursor` time with `(cursor, game_ctx, menu_ctx)` that initializes any cursor state (e.g. the opaque `path` field) and returns the per-move callback. `move_cursor` invokes it after position changes.
- `self.path` and `self.legal_tiles` remain on the node as opaque fields, since `serialize`/`deserialize` and `battle_ui_context` consume them.
- Updated the two battle pathfinding call sites in `battle_menu_manager.lua` (SELECT_DESTINATION, SELECT_TARGET) and the grid spec tests to use `with_on_move`.

Tests: 1293 successes / 0 failures. Verified grid.lua has no remaining references to HIGHLIGHT, pathfinding, or anything under `src/tactics/battle/`, `campaign/`, or `game/`.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
