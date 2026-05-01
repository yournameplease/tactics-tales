---
id: DRAFT-4
title: Replace AI engine camera callback with event bus subscription
status: Draft
assignee: []
created_date: '2026-05-01 02:34'
labels:
  - architecture
  - battle
  - ai
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After construction, `BattleManager` assigns a closure onto `enemy_ai_engine.on_unit_action` that calls `battle_ui_ctx:move_camera()`. The AI engine has an implicit UI dependency injected via field assignment after the fact. If camera logic changes, `battle_manager.lua` is the edit point — invisible to both the AI engine and the UI context.

**Proposed direction:** The AI engine emits unit-action events onto the event bus. `BattleUIContext` subscribes to that event and handles camera movement itself. The AI engine knows nothing about cameras; the camera knows nothing about AI internals.

**Benefits:**
- Tests for AI behavior don't need a UI stub
- Camera logic lives with the UI
- The event bus becomes a real seam (currently only used for BATTLE_END)

**Files:** `src/tactics/battle/battle_manager.lua`, `src/tactics/battle/tactics/ai_engine.lua`, `src/tactics/battle/battle_ui_context.lua`
<!-- SECTION:DESCRIPTION:END -->
