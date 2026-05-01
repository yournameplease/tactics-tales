---
id: DRAFT-3
title: Replace hardcoded UIContextManager priority with priority-at-registration
status: Draft
assignee: []
created_date: '2026-05-01 02:34'
labels:
  - architecture
  - ui
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`UIContextManager` hardcodes `battle > story > game` priority using concrete type-specific fields (`self.battle_context`, etc.). Adding any new phase (deployment, overworld) requires editing this central coordinator and adding a new field. It fails the deletion test: delete it and the same priority logic scatters to call sites.

**Proposed direction:** Contexts register with a numeric priority at registration time. The manager becomes a pure priority queue with no knowledge of concrete types. Concrete contexts are adapters that know their own priority.

**Benefits:**
- New UI phases add zero lines to the manager
- Manager is testable in isolation with stub contexts
- Depth increases: one smart concept (priority-driven context selection) behind a tiny interface

**Files:** `src/tactics/ui/ui_context_manager.lua`, `src/tactics/battle/battle_ui_context.lua`, `src/tactics/story/story_ui_context.lua`, `src/tactics/game/game_ui_context.lua`
<!-- SECTION:DESCRIPTION:END -->
