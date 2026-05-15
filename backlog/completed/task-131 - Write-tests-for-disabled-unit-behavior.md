---
id: TASK-131
title: Write tests for disabled unit behavior
status: Done
assignee: []
created_date: '2026-05-14 14:04'
updated_date: '2026-05-15 02:17'
labels: []
milestone: m-19
dependencies:
  - TASK-127
  - TASK-128
  - TASK-129
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add unit tests covering the disabled unit feature in `src/spec/battle/scripts/script_manager_spec.lua` (and/or a new battle_map spec if appropriate).

**Scenarios to cover:**
- A unit spawned with `disabled = true` is not returned by `battle_map:get_units(fp.fn_true)`
- A disabled unit does not appear in `get_targets_in_range` results
- `modify_units` with `{ type = "modify_units", unit_selector = { type = "tag_lookup", tag = "..." }, enabled = false }` disables a live unit; it disappears from `get_units`
- `modify_units` with `enabled = true` on a disabled unit re-enables it; it reappears in `get_units`
- A disabled unit that is re-enabled can be targeted and takes turns normally

Follow the test style in `src/spec/battle/scripts/script_manager_spec.lua`: use `make_sm`, `make_engine`, `make_map`, `pump`.

Depends on TASK-127 (filtering) and TASK-128 (modify_units effect).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Test: disabled unit is excluded from `get_units`
- [x] #2 Test: disabled unit is excluded from `get_targets_in_range`
- [x] #3 Test: `modify_units { enabled = false }` disables a live unit
- [x] #4 Test: `modify_units { enabled = true }` re-enables a disabled unit
- [x] #5 All new tests pass under `make test`
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
