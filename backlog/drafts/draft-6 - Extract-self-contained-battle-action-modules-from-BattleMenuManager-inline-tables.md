---
id: DRAFT-6
title: >-
  Extract self-contained battle action modules from BattleMenuManager inline
  tables
status: Draft
assignee: []
created_date: '2026-05-01 02:35'
labels:
  - architecture
  - battle
  - menu
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`battle_menu_manager.lua` is 883 lines: 21 handlers and ~500 lines of step definitions as one monolithic `MENU_DATA` table. Adding a new battle action requires finding the right insertion point inside this table and adding both a step definition and a handler entry. Common patterns (tile picker, unit picker, confirmation flow) are duplicated without extraction. There is no enforced shape for a "menu action" — it's duck-typed.

**Proposed direction:** A typed "battle action" module declares its own step definition, preconditions, and handler as one unit. The menu manager assembles registered actions rather than defining all of them. Common patterns (target selection, confirmation) become deep building blocks shared across actions.

**Benefits:**
- New battle actions are self-contained — one file to add
- Tests target individual actions, not the full 883-line manager
- Menu manager shrinks to wiring, not definition
- Common patterns get locality and can be independently tested

**Files:** `src/tactics/battle/battle_menu_manager.lua`, `src/tactics/menu/menu_manager.lua`
<!-- SECTION:DESCRIPTION:END -->
