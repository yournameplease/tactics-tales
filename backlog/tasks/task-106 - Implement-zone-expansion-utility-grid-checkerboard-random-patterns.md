---
id: TASK-106
title: 'Implement zone expansion utility (grid, checkerboard, random patterns)'
status: To Do
assignee: []
created_date: '2026-05-09 17:01'
labels: []
milestone: m-16
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create a new mod-level utility library `mods/base/lib/zones.lua` (following the pattern of `mods/base/lib/script.lua` and `mods/base/lib/battle.lua`) that mission factories can include to expand a RectZone into a list of tile positions.

Public API:
- `zones.expand(rect, pattern, count, rng?) → Point[]`
  - `rect`: a `RectZone { x, y, w, h }` from `map_context.rect_zones`
  - `pattern`: `"grid"` | `"checkerboard"` | `"random"`
  - `count`: max units to place (integer, result of `zones.unit_count`)
  - `rng`: optional RngInstance (needed for `"random"` pattern); if absent, random falls back to sequential
  - `"grid"`: row-major (left-to-right, top-to-bottom) fill, stops at count
  - `"checkerboard"`: every other tile in row-major order (columns where `(x+y) % 2 == 0`), stops at count
  - `"random"`: collect all tiles in the rect, shuffle via `rng:choose_random_from_list` repeatedly (or Fisher-Yates), return first count
- `zones.unit_count(budget, slot_cost) → integer` — `math.floor(budget / slot_cost)`

The library should be includeable via `include("mods/base/lib/zones.lua")` and return a `zones` table.

Depends on TASK-103 (RectZone type).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 zones.expand with 'grid' pattern on a 3x2 rect with count=4 returns exactly 4 points in row-major order.
- [ ] #2 zones.expand with 'checkerboard' pattern returns only alternating tiles, capped at count.
- [ ] #3 zones.expand with 'random' pattern and a seeded rng is deterministic for the same seed.
- [ ] #4 zones.unit_count(12, 5) returns 2.
- [ ] #5 Unit tests in a new spec file cover all three patterns and zones.unit_count.
- [ ] #6 make test is green.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
