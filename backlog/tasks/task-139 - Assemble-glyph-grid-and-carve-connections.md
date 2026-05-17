---
id: TASK-139
title: Assemble glyph grid and carve connections
status: To Do
assignee: []
created_date: '2026-05-17 00:40'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per spec §8 steps 8–11: roll exit widths from the theme distribution (clamped to overlap) and positions within overlap; place all cell interiors into a 16×16 glyph grid at their computed positions; fill wall gaps and border margin with `#`; carve each connection by erasing wall glyphs at the rolled position and width through the full wall gap. Flag width-1 bridge connections (using bridge detection from earlier task) and place an `enemy_commander` spawn glyph at the center tile of each.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Output is a 16×16 character grid with valid vocabulary only.
- [ ] #2 Every connection in the graph corresponds to a passable rectangular cut of the rolled width.
- [ ] #3 Width-1 bridge connections carry an `enemy_commander` glyph at the passage center.
- [ ] #4 Spec verifies for a fixed seed that the grid is reproducible and connected via flood-fill from the deployment cell.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
