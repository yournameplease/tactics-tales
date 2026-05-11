---
id: TASK-113
title: Wire authored facing through UnitSpawnData and unit_spawner
status: To Do
assignee: []
created_date: '2026-05-11 22:52'
labels: []
milestone: m-17
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add an optional `facing` field to `UnitSpawnData` and plumb it through to `unit_spawner.try_spawn_at`.

**`src/tactics/battle/unit/spawn_data.lua`**
```lua
---@class UnitSpawnData
-- ... existing fields ...
---@field facing? CardinalDirection  -- "up"|"down"|"left"|"right"; overrides position-derived default when present
```

**`src/tactics/battle/unit_spawner.lua`** — `try_spawn_at`:
- Accept the full `spawn_data` (or add a `facing?` param) so the authored facing is available
- When `spawn_data.facing` is present, use `character.facing.of(spawn_data.facing)` instead of the position-derived `facing_r` logic

The resolver translates compass directions from the meta (`north`→`up`, `south`→`down`, `east`→`right`, `west`→`left`) before writing to `UnitSpawnData.facing`. The engine type stays `CardinalDirection`.

Fallback: when `facing` is absent, keep existing position-derived behavior (left half of map → `right`, right half → `left`).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 UnitSpawnData has optional facing field (CardinalDirection)
- [ ] #2 unit_spawner uses authored facing when present, falls back to position-derived otherwise
- [ ] #3 Existing tests still pass
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
