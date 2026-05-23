---
id: TASK-154
title: Decouple grid cursor from battle pathfinding via on_move hook
status: To Do
assignee: []
created_date: '2026-05-22 23:36'
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
- [ ] #1 grid.lua has no require of src.tactics.battle.* or src.tactics.constants
- [ ] #2 Battle screens using the grid cursor still extend paths correctly when moving over IS_VALID tiles
- [ ] #3 Existing tests for grid cursor and any affected battle UI flows pass
- [ ] #4 Hook surface is minimal — no speculative callbacks added beyond what current call sites need
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
