---
id: TASK-61
title: >-
  Parameterize MenuHandler on session_context type and move handlers into
  MenuDefinition
status: Done
assignee: []
created_date: '2026-05-03 13:52'
updated_date: '2026-05-03 14:43'
labels:
  - cleanup
  - lua
  - types
milestone: m-11
dependencies: []
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
## Context

TASK-57 parameterized `MenuHandler` on `TServices`, eliminating `---@cast services` annotations inside handler lambdas. The `session_context` parameter remains typed as the abstract `MenuContext`, forcing `---@cast session_context BattleMainMenuContext` (and similar) annotations inside any handler that uses battle- or campaign-specific session state.

Unlike `services` (constant per manager), `session_context` is constant per **menu** — `MENU_DEPLOYMENT` and `MENU_PLAYER_TURN` each have their own session context type. This means a single flat handler map per manager cannot carry per-menu session context typing. The fix requires moving handler ownership from the flat `menu_handlers` argument into `MenuDefinition` itself.

## Change

### 1. Add `TSession` to `MenuHandler`

```lua
---@alias MenuHandler<TServices, TSession> fun(services: TServices, menu_data: table<string, any>, session_context: TSession, value: any): MenuHandlerPostHandling?
```

### 2. Add typed handler map to `MenuDefinition`

```lua
---@class MenuDefinition<TServices, TSession>
---@field initial_step string
---@field steps table<string, MenuStepDefinition>
---@field handlers table<string, MenuHandler<TServices, TSession>>
```

Each concrete menu definition owns its handler map, typed for that menu's specific session context:

```lua
-- battle_menu_manager.lua
local MENU_PLAYER_TURN = {
    initial_step = "SELECT_UNIT",
    handlers = {}, ---@type table<string, MenuHandler<BattleMenuContext, BattleMainMenuContext>>
    steps = { ... }
}
```

### 3. Remove the flat `menu_handlers` param from `menu_manager.new`

`MenuManager` currently takes a single flat `table<string, MenuHandler>`. Once handlers live in `MenuDefinition`, this parameter is removed. `BaseMenuManager:update` (and related methods) look up handlers from `self.menu_definitions[self.menu_state.menu_id].handlers`.

### 4. Migrate concrete managers

Each manager currently builds one flat HANDLERS table. Replace with per-menu handler tables inlined into each `MenuDefinition`.

**battle_menu_manager.lua** — split into `MENU_DEPLOYMENT` handlers and `MENU_PLAYER_TURN` handlers (and any others). Remove all `---@cast session_context BattleMainMenuContext` annotations from handler lambdas.

**campaign_menu_manager.lua** — `MENU_CUSTOMIZE_CHARACTER`, `MENU_TEXT_INPUT`, and `MENU_SELECT_OPTION` each get their own typed handler map. `MENU_TEXT_INPUT` currently merges keyboard handlers via `maps.add_all(HANDLERS, menu_keyboard.handlers)`.

**game_menu_manager.lua** — similar split per menu.

### 5. Resolve the keyboard handler migration

`menu_keyboard` currently exposes a `handlers` table (typed `table<string, MenuHandler<GameContext>>`) that campaign merges into its flat HANDLERS map. Once handlers live in `MenuDefinition`, this no longer works as-is.

**Decision needed at implementation time:** `menu_keyboard` should return both the step definition and its handler map together — either as a two-value return from `menu_keyboard.step(...)` or as a small struct `{ step, handlers }`. The campaign manager's `MENU_TEXT_INPUT` definition then takes the step and installs the keyboard handlers directly.

## Files

- `src/tactics/menu/menu_manager.lua` — add `TSession` to `MenuHandler`; update `MenuDefinition`, `MenuManager`, and `menu_manager.new`
- `src/tactics/menu/on_screen_keyboard.lua` — expose handler map alongside step definition
- `src/tactics/battle/battle_menu_manager.lua` — split HANDLERS into per-menu maps; remove session_context casts
- `src/tactics/campaign/campaign_menu_manager.lua` — split HANDLERS into per-menu maps; migrate keyboard handler merge
- `src/tactics/game/game_menu_manager.lua` — split HANDLERS into per-menu maps
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 MenuHandler alias has two type parameters: TServices and TSession
- [x] #2 MenuDefinition carries a typed handler map; menu_manager.new no longer takes a flat menu_handlers argument
- [x] #3 No ---@cast session_context annotations inside any handler lambda in any manager
- [x] #4 menu_keyboard exposes its handler map alongside its step definition
- [x] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
