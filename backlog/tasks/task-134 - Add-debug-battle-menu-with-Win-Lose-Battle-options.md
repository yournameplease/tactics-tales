---
id: TASK-134
title: Add debug battle menu with Win/Lose Battle options
status: Done
assignee: []
created_date: '2026-05-16 19:52'
updated_date: '2026-05-16 20:03'
labels: []
milestone: m-20
dependencies:
  - TASK-132
  - TASK-133
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Wire up the in-battle debug menu in `src/tactics/battle/battle_menu_manager.lua`.\n\nChanges needed:\n1. Add two handlers to `PLAYER_TURN_HANDLERS`:\n   - `debug_win`: calls `services.tactics_engine:force_battle_result(\"VICTORY\")`\n   - `debug_lose`: calls `services.tactics_engine:force_battle_result(\"DEFEAT\")`\n2. Add a new `DEBUG_MENU` step to `MENU_PLAYER_TURN.steps`:\n   - A `list.column` with buttons \"Win Battle\" (handler: `debug_win`), \"Lose Battle\" (handler: `debug_lose`), and \"Back\" (`then_go_back()`)\n   - `with_previous_step(\"TURN_MENU\")`\n3. In `TURN_MENU`'s list builder, conditionally insert a \"Debug Menu\" button (advances to `DEBUG_MENU`) when `DYNAMIC_CONFIG.debug_mode` is true — following the same pattern as the `tutorial_mode` guard on \"End Turn\"\n\nThis task depends on TASK-132 (debug_mode config) and TASK-133 (force_battle_result).\n\nAcceptance criteria:\n- When `debug_mode` is false, TURN_MENU contains no Debug Menu entry\n- When `debug_mode` is true, TURN_MENU contains a \"Debug Menu\" button that navigates to DEBUG_MENU\n- DEBUG_MENU has Win Battle, Lose Battle, and Back\n- Selecting Win Battle ends the battle with VICTORY; Lose Battle ends with DEFEAT
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
