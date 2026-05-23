---
id: TASK-156
title: 'Split ui_context_manager: extract generic context stack'
status: Done
assignee: []
created_date: '2026-05-22 23:36'
updated_date: '2026-05-23 01:14'
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
- [x] #1 Engine-side context manager has no require of src.tactics.battle.*, src.tactics.campaign.*, or src.tactics.game.*
- [x] #2 Game-side glue file wires the three existing contexts together and the running game behaves identically
- [x] #3 Existing tests covering context transitions pass
- [x] #4 The engine primitive can be instantiated against a different set of contexts in a unit test (smoke-level is fine) without modifying engine code
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Split `src/tactics/ui/ui_context_manager.lua` into:

- **Engine primitive** — `src/tactics/ui/ui_context_stack.lua`: a generic `UIContextStack` keyed on each context's `type` field. Constructor takes `{ layout_priority, default_layout }` for primary-layout selection. Registered contexts are stored in `self.contexts[type]` and mirrored as `self[type .. "_context"]` for typed game-side access. Only requires `src.tactics.ui.ui_context` and `src.tactics.ui.types`.
- **Game-side glue** — `src/tactics/ui/ui_context_manager.lua`: tactics-specific factory that calls `ui_context_stack.new({ layout_priority = { "battle", "campaign", "game" }, default_layout = "TITLE_SCREEN" })` and declares `UIContextManager : UIContextStack` with the typed `battle_context?` / `campaign_context?` / `game_context?` / `TacticsLayoutId` fields. Existing callers (`main.lua`, `battle_manager`, `game`, layouts, panels) keep using `ui_context_manager.new()` and `.battle_context` etc. unchanged.

Also generalized `UIContext`: declared `enrich` on the interface, made `UIContextType` a generic `string` alias.

New spec `src/spec/ui/ui_context_stack_spec.lua` exercises the engine primitive against a fabricated `gameplay`/`pause_menu` priority — demonstrating AC #4 (instantiable for a different game shape without engine changes).
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
