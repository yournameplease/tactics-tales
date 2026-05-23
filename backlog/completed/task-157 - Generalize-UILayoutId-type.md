---
id: TASK-157
title: Generalize UILayoutId type
status: Done
assignee: []
created_date: '2026-05-22 23:36'
updated_date: '2026-05-23 01:06'
labels: []
milestone: m-24
dependencies: []
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
`src/tactics/ui/types.lua` defines:

```
---@alias UILayoutId "TITLE_SCREEN"|"TITLED_MENU_PAGE"|"TACTICS"|"COMBAT_PREVIEW"|"CAMPAIGN_PAGE"
```

This is a type-level domain leak — every consumer of the engine that touches `UILayoutId` inherits tactics screen IDs.

Change the engine-side definition to a generic alias (e.g. `---@alias UILayoutId string`). In the game's tactics namespace, define a narrowed alias (e.g. `TacticsLayoutId`) that enumerates the actual screens, and update consumers to use whichever is appropriate.

Verify with the LuaCATS type checker that no new type errors are introduced and that existing call sites still type-check.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Engine-side UILayoutId is generic (no tactics screen names in the engine namespace)
- [x] #2 Tactics-specific screen IDs are still enumerated in a narrowed alias in the game namespace
- [x] #3 Type-checker run shows no new errors versus baseline
- [x] #4 Tests pass
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Engine-side `UILayoutId` in `src/tactics/ui/types.lua` is now `string` (generic). Introduced `TacticsLayoutId` in new `src/tactics/ui/layout/types.lua` enumerating the tactics screen IDs. Updated game-side consumers (`game_ui_context`, `ui_context_manager`, layout/tactics, layout/game) to reference the narrowed alias; engine consumers (`ui_context`, `ui_manager`, `layout`) continue to use generic `UILayoutId`. Type-check matches baseline (no new errors) and `make test` passes (1293/1293).
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
