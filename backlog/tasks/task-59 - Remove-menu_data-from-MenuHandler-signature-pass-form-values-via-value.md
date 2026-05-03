---
id: TASK-59
title: Remove menu_data from MenuHandler signature; pass form values via value
status: In Progress
assignee: []
created_date: '2026-05-03 05:20'
updated_date: '2026-05-03 18:23'
labels:
  - cleanup
  - lua
milestone: m-11
dependencies: []
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The `MenuHandler` signature passes `menu_data: table<string, any>` (the full serialized node tree) to every handler, but nearly all handlers ignore it. The handful that use it do so only to pass form values to a callback — a coupling to serialization key names that leaks the node layer into the handler layer.

## Current signature

```lua
---@alias MenuHandler fun(services: GameContext, menu_data: table<string, any>, session_context: MenuContext, value: any): MenuHandlerPostHandling?
```

## Handlers that currently use `menu_data`

- `create_character` (campaign) — passes `menu_data` directly to `services.handle_create_character(menu_data)`. The intent is to forward the current character appearance form state.
- `apply_preset` (game) — iterates `menu_data` keys to build a deserialization table.

All other handlers ignore `menu_data` entirely.

## Change

Remove `menu_data` from the signature:

```lua
---@alias MenuHandler fun(services: GameContext, session_context: MenuContext, value: any): MenuHandlerPostHandling?
```

For `create_character`: the manager's `call_handler` dispatch path already serializes node state before calling the handler. Instead, pass the serialized form data as `value` at the call site where the handler is invoked, so the handler receives it without knowing about the serialization layer.

For `apply_preset`: same approach — the game menu manager can pass the relevant data as `value`.

## Files
- `src/tactics/menu/menu_manager.lua` — remove `menu_data` from `MenuHandler` alias; update all dispatch call sites (several `handler(self.game_ctx, self:serialize().node.data, ...)` calls) to drop the argument or fold it into `value`
- `src/tactics/campaign/campaign_menu_manager.lua` — update `create_character` handler
- `src/tactics/game/game_menu_manager.lua` — update `apply_preset` and any other handlers that read `menu_data`
- `src/tactics/battle/battle_menu_manager.lua` — mechanical removal of the unused parameter from all 22 handler signatures

## Acceptance criteria
- `menu_data` parameter is gone from `MenuHandler` and all handler implementations
- `make test` passes
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
