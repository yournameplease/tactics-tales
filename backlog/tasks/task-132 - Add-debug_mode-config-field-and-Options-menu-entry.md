---
id: TASK-132
title: Add debug_mode config field and Options menu entry
status: To Do
assignee: []
created_date: '2026-05-16 19:52'
labels: []
milestone: m-20
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `debug_mode` (boolean, default `false`) to the game's dynamic configuration system and expose it in the Options menu.\n\nFiles to modify:\n- `src/tactics/config/config_manager.lua` — add `---@field debug_mode? boolean` to `DynamicConfig` annotation and `debug_mode = false` to `DEFAULT_CONFIG`\n- `src/tactics/game/game_menu_manager.lua` — add a `debug_mode` YES/NO `selection.row` to `options_selections` in `OPTIONS_MENU`, alongside the existing `profile`/`log_level` entries\n\nAcceptance criteria:\n- `DYNAMIC_CONFIG.debug_mode` is `false` when no user config is present\n- The Options menu shows a \"Debug Mode\" YES/NO toggle\n- Saving options persists the value through the existing `store_config` path\n- LuaCATS annotation `---@field debug_mode? boolean` is present on `DynamicConfig`
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
