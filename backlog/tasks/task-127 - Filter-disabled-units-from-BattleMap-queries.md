---
id: TASK-127
title: Filter disabled units from BattleMap queries
status: Done
assignee: []
created_date: '2026-05-14 14:03'
updated_date: '2026-05-14 22:22'
labels: []
milestone: m-19
dependencies:
  - TASK-126
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update `src/tactics/battle/battle_map.lua` to exclude disabled units from standard queries.

**Changes:**
- `get_units(filter)`: add `and not unit.disabled` to the loop body so all downstream callers (turn manager, AI, script selectors, rendering) automatically skip disabled units.
- `get_units_including_disabled(filter)`: new method — identical structure to `get_units` but without the disabled guard. Used by the modify_units effect handler when enabling units that are currently disabled.
- `get_targets_in_range(unit_id, tile)`: this method iterates `self.units_by_id` directly (bypasses `get_units`). Add `and not target.disabled` to its filter condition.

Depends on TASK-126 (disabled field must exist).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 `get_units(fp.fn_true)` does not return units with `disabled = true`
- [x] #2 `get_units_including_disabled(fp.fn_true)` returns all units including disabled ones
- [x] #3 `get_targets_in_range` does not return disabled units
- [x] #4 `make test` passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
