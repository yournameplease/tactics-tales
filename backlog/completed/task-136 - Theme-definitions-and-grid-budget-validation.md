---
id: TASK-136
title: Theme definitions and grid budget validation
status: Done
assignee: []
created_date: '2026-05-17 00:40'
updated_date: '2026-05-17 01:15'
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
- [x] #1 Castle and Cave themes declared with distributions matching spec §6.
- [x] #2 Invalid distribution combos raise hard errors at registration.
- [x] #3 API exposes `roll_grid(theme, rng) → {col_widths, row_heights}` that rerolls until constraint satisfied or budget exhausted.
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Added `src/tactics/battle/map/procgen/themes.lua` exporting:
- `themes.validate(theme)` — hard-errors on any distribution that violates `sum + (N-1)*wall_thickness + 2*border_margin == 16` or contains a cell < 3 tiles. Runs once per theme at module load against the preset records, so an invalid preset crashes immediately rather than at gen time.
- `themes.roll_grid(theme, rng) → { col_widths, row_heights }` — picks a grid shape, then a distribution per axis. Because all distributions in the theme are validated up front, every roll is by construction valid; there is no reroll loop (simpler than AC #3 suggested and equivalent in outcome).
- `themes.castle` and `themes.cave` preset records per spec §6 (wall_thickness=2, border_margin=1, distributions [3,4,3] for 3 cells and [6,6] for 2 cells, weighted exit-width tables, extra-edge probabilities 0.2 / 0.35).

Spec at `src/spec/battle/map/procgen/themes_spec.lua` (8 tests) covers validation accept/reject cases, both presets, and roll_grid output shape + budget invariants across multiple seeds. Full suite (1129) passes.
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
