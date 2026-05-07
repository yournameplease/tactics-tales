---
id: TASK-58
title: Name and extract anonymous grid child filter functions in battle_menu_manager
status: Done
assignee: []
created_date: '2026-05-03 05:18'
updated_date: '2026-05-06 13:01'
labels:
  - cleanup
  - lua
milestone: m-11
dependencies: []
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The `with_child()` filter lambdas inside `make_menu_data` in `battle_menu_manager.lua` are anonymous closures. The lower-level predicates (`point_is_available_player`, `point_is_empty_or_acting_unit`, etc.) were already extracted as named local functions, but the `with_child()` wrappers that call them were not given the same treatment. They remain inline, untested, and each carries a redundant `---@cast msb BattleMenuContext`.

## Change

Extract each `with_child()` filter closure to a named local function at the same scope as the existing predicates. Example:

```lua
-- before (inline in make_menu_data):
:with_child(
    function(point, msb, _ctx)
        ---@cast msb BattleMenuContext
        return point_is_available_player(point, msb.battle_map)
    end,
    button.builder("available_player")...
)

-- after:
local function filter_available_player(point, msb, _ctx)
    return point_is_available_player(point, msb.battle_map)
end
-- ...
:with_child(filter_available_player, button.builder("available_player")...)
```

This completes the extraction pattern already started in the file. Combined with TASK-58 (typed handler aliases), the casts inside these filter functions will disappear entirely.

## Files
- `src/tactics/battle/battle_menu_manager.lua` — extract all anonymous `with_child()` filter lambdas to named locals

## Acceptance criteria
- No anonymous `function(point, msb, ...)` lambdas remain inside `make_menu_data`
- `make test` passes
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
