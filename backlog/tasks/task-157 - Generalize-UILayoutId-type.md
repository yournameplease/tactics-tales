---
id: TASK-157
title: Generalize UILayoutId type
status: To Do
assignee: []
created_date: '2026-05-22 23:36'
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
- [ ] #1 Engine-side UILayoutId is generic (no tactics screen names in the engine namespace)
- [ ] #2 Tactics-specific screen IDs are still enumerated in a narrowed alias in the game namespace
- [ ] #3 Type-checker run shows no new errors versus baseline
- [ ] #4 Tests pass
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
