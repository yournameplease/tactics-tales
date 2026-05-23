---
id: TASK-156
title: 'Split ui_context_manager: extract generic context stack'
status: To Do
assignee: []
created_date: '2026-05-22 23:36'
labels: []
milestone: m-24
dependencies: []
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`src/tactics/ui/ui_context_manager.lua` hard-codes the tactics-specific nesting by importing:

- `src.tactics.battle.battle_ui_context`
- `src.tactics.campaign.campaign_ui_context`
- `src.tactics.game.game_ui_context`

The action game extraction target will have a different context nesting (e.g. game menus → gameplay → pause menu), so the engine half must not know which contexts exist.

Split this file into two pieces:

1. **Engine primitive** — a context stack / manager that knows nothing about which contexts exist. Handles push/pop/swap, lifecycle hooks, and whatever generic semantics the current manager provides.
2. **Game-specific glue** — a thin file in the game's tactics namespace that instantiates the engine primitive and wires up `game_ui_context` → `campaign_ui_context` → `battle_ui_context`.

The engine primitive's API should be expressive enough that the game glue is small and declarative.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Engine-side context manager has no require of src.tactics.battle.*, src.tactics.campaign.*, or src.tactics.game.*
- [ ] #2 Game-side glue file wires the three existing contexts together and the running game behaves identically
- [ ] #3 Existing tests covering context transitions pass
- [ ] #4 The engine primitive can be instantiated against a different set of contexts in a unit test (smoke-level is fine) without modifying engine code
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
