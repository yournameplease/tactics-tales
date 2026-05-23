---
id: TASK-155
title: Invert ui_manager screen registry
status: Done
assignee: []
created_date: '2026-05-22 23:36'
updated_date: '2026-05-23 00:58'
labels: []
milestone: m-24
dependencies: []
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`src/tactics/ui/ui_manager.lua` directly `require`s four tactics-specific layouts:

- `src.tactics.ui.layout.campaign_page`
- `src.tactics.ui.layout.game`
- `src.tactics.ui.layout.tactics`
- `src.tactics.ui.layout.title_screen`

This hard-codes the screen registry into the manager, blocking reuse by a different game with different screens.

Refactor `ui_manager` to accept a layout registry (e.g. a map of `UILayoutId` → layout module) from the game at construction or startup. The four tactics layouts should be registered by the game's top-level wiring, not imported by the manager itself.

Keep the call surface (whatever `ui_manager` exposes for switching/rendering layouts) the same — only the source of the layout set changes.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ui_manager.lua has zero requires of src.tactics.ui.layout.*
- [x] #2 Game startup wiring registers the four existing layouts and the running game looks identical
- [x] #3 Existing UI/integration tests pass
- [x] #4 It is possible to construct a ui_manager instance with a different (or empty) layout set without modifying ui_manager.lua
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
