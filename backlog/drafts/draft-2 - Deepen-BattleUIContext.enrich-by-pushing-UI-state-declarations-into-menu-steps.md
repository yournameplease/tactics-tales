---
id: DRAFT-2
title: >-
  Deepen BattleUIContext.enrich() by pushing UI state declarations into menu
  steps
status: Draft
assignee: []
created_date: '2026-05-01 02:34'
labels:
  - architecture
  - battle
  - ui
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`BattleUIContext.enrich()` is 203 lines containing 14+ comparisons against menu step name strings (`"SELECT_UNIT"`, `"SELECT_DESTINATION"`, etc.). Every new menu step requires edits in both `battle_menu_manager.lua` (step definition) and `battle_ui_context.lua` (new branch). The menu step seam leaks UI derivation rules into the context object.

**Proposed direction:** Each menu step declares the UI state it implies — which unit is acting, what's hovered, whether a path shows — rather than having `enrich()` infer it post-hoc. Enrichment collapses to reading those declarations.

**Benefits:**
- New menu steps add zero lines to `enrich()`
- Tests for UI derivation no longer need to simulate full menu state
- Locality improves — step definitions are complete in one place

**Files:** `src/tactics/battle/battle_ui_context.lua`, `src/tactics/battle/battle_menu_manager.lua`
<!-- SECTION:DESCRIPTION:END -->
