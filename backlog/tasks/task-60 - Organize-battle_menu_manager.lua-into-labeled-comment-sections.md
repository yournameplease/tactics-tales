---
id: TASK-60
title: Organize battle_menu_manager.lua into labeled comment sections
status: To Do
assignee: []
created_date: '2026-05-03 05:27'
labels:
  - cleanup
  - lua
milestone: m-11
dependencies: []
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
At 894 lines, `battle_menu_manager.lua` mixes tile queries, 22 handlers across five domains, the step topology, and module setup. No structural change is needed — just add comment-section headers to make the file navigable and to establish where new code belongs.

## Proposed section layout

```
-- [ Tile queries ] ----------------------------------------
--   Point/unit predicates: point_is_available_player, etc.

-- [ Tile highlight providers ] ----------------------------
--   Bitmask-returning functions: get_deployment_tiles, etc.

-- [ Handlers: deployment ] --------------------------------
--   select_swap_unit, swap_units

-- [ Handlers: unit selection ] ----------------------------
--   select_acting_unit, mark_unit, mark/unmark_all_units,
--   cycle_next/previous_unit, is_acting_unit_after/before helpers

-- [ Handlers: movement ] ----------------------------------
--   move_acting_unit, unmove_acting_unit,
--   move_and_store_attack_unit, move_and_store_interaction_unit

-- [ Handlers: combat & interaction ] ----------------------
--   store_attack_unit, attack_unit, attack_unit_at_tile,
--   cycle_attack_position, handle_interaction

-- [ Handlers: turn management ] ---------------------------
--   start_battle, end_turn, wait_acting_unit,
--   navigate_to_turn_menu, navigate_to_deployment_menu

-- [ Step topology ] ---------------------------------------
--   BattlePreparationsContext annotation, make_menu_data()

-- [ Module ] ----------------------------------------------
--   battle_menu_manager table and .new()
```

## Files
- `src/tactics/battle/battle_menu_manager.lua` — add section headers only; no logic changes

## Acceptance criteria
- Each section header is present and all existing code sits under the correct section
- `make test` passes
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
