---
id: TASK-136
title: Theme definitions and grid budget validation
status: To Do
assignee: []
created_date: '2026-05-17 00:40'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Define Castle and Cave themes in code per spec §6 (wall_thickness, border_margin, col/row distribution tables, exit width weighted table, extra-edge probability). Implement budget validation that enforces `sum(distribution) + (N-1)*wall_thickness + 2*border_margin == 16` and minimum cell dim ≥ 3. Validation runs at theme registration and at distribution roll time.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Castle and Cave themes declared with distributions matching spec §6.
- [ ] #2 Invalid distribution combos raise hard errors at registration.
- [ ] #3 API exposes `roll_grid(theme, rng) → {col_widths, row_heights}` that rerolls until constraint satisfied or budget exhausted.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
