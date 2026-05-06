---
id: TASK-88
title: Add boundary and variance tests to combat calculator spec
status: Done
assignee: []
created_date: '2026-05-05 13:19'
updated_date: '2026-05-06 03:18'
labels: []
milestone: m-14
dependencies: []
references:
  - src/spec/battle/combat/combat_calculator_spec.lua
  - src/tactics/battle/combat/combat_calculator.lua
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The combat calculator spec only tests RNG extremes: `always_hit()` (roll=0) and `always_miss()` (roll=99). Near-boundary cases and damage variance are never exercised. The RNG override seam is correct; it just needs more test cases through it.

Add parametric tests using the existing `rnd_returns(val)` mechanism to cover: hit/miss at the exact boundary, one below, one above; damage at min/max/midpoint of range.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Test: hit_chance=85, roll=84 → hit
- [x] #2 Test: hit_chance=85, roll=85 → miss
- [x] #3 Test: hit_chance=85, roll=86 → miss
- [x] #4 Existing passing tests remain green
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
