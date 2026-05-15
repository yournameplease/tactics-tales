---
id: TASK-128
title: Extend modify_units effect with enabled field
status: Done
assignee: []
created_date: '2026-05-14 14:03'
updated_date: '2026-05-14 22:45'
labels: []
milestone: m-19
dependencies:
  - TASK-126
  - TASK-127
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add support for enabling/disabling units via the `modify_units` script effect.

**Changes:**

`src/tactics/battle/scripts/battle_script.lua` — add `---@field enabled? boolean` to `ModifyUnits`. When set: `true` → `disabled = false`; `false` → `disabled = true`.

`src/tactics/battle/tactics/tactics_engine.lua` — in `TacticsEngine:modify_units(units, props)`, handle the new field:
```lua
if props.enabled ~= nil then
    u.disabled = not props.enabled
end
```

`src/tactics/battle/scripts/script_manager.lua` — in the `modify_units` effect handler (around line 234), when `effect.enabled ~= nil`, resolve the unit selector using `battle_map:get_units_including_disabled(...)` instead of the standard path (which would miss currently-disabled units when re-enabling them). The standard `resolve_unit_selector` path is used when `enabled` is nil.

Depends on TASK-126 (disabled field) and TASK-127 (get_units_including_disabled method).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `ModifyUnits` type has an `enabled? boolean` field documented
- [x] #2 A script with `{ type = "modify_units", ..., enabled = false }` sets `unit.disabled = true` on matched units
- [x] #3 A script with `enabled = true` targeting a disabled unit re-enables it (`disabled = false`)
- [x] #4 Resolving the selector for `enabled ~= nil` uses `get_units_including_disabled` so disabled units can be found
- [x] #5 `make test` passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
