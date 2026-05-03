---
id: TASK-57
title: Parameterize MenuHandler services type to eliminate cast annotations
status: Done
assignee: []
created_date: '2026-05-03 05:18'
updated_date: '2026-05-03 13:39'
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
Each concrete menu manager instance always uses exactly one `GameContext` subtype as `services`, but the `MenuHandler` alias declares it as the abstract `GameContext`. This forces 22 `---@cast` annotations in `battle_menu_manager.lua` alone (plus a handful in the campaign and game managers) — noise that would fail silently at runtime if the wrong context were passed.

## Change

Parameterize `MenuHandler` on the services type:

```lua
---@alias MenuHandler<TServices> fun(services: TServices, menu_data: table<string, any>, session_context: MenuContext, value: any): MenuHandlerPostHandling?
```

Each concrete manager declares its own handler alias:

```lua
---@alias BattleMenuHandler MenuHandler<BattleMenuContext>
---@alias CampaignMenuHandler MenuHandler<StoryMenuServices>
---@alias GameMenuHandler MenuHandler<GameUIContext>
```

And uses it for its HANDLERS table and `MenuDefinition` steps.

## Files
- `src/tactics/menu/menu_manager.lua` — update `MenuHandler` alias and `MenuDefinition`/`MenuManager` types to carry the type parameter through
- `src/tactics/battle/battle_menu_manager.lua` — replace all 22 `---@cast msb BattleMenuContext` / `---@cast services BattleMenuContext` with typed alias; remove casts
- `src/tactics/campaign/campaign_menu_manager.lua` — same for `StoryMenuServices`
- `src/tactics/game/game_menu_manager.lua` — same for `GameUIContext`

## Acceptance criteria
- All `---@cast` annotations on the `services` parameter inside handler lambdas are removed
- `make test` passes
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
