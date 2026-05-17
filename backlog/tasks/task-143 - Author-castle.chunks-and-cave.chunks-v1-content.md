---
id: TASK-143
title: Author castle.chunks and cave.chunks v1 content
status: To Do
assignee: []
created_date: '2026-05-17 00:41'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
ordinal: 9000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Author a sufficient chunk pool for both themes in `mods/tt_procedural_campaign/game_data/chunks/`. Each theme needs at least: one `deployment`-tagged chunk per cell dimension in its distribution table; multiple non-deployment chunks per dimension with varied exit-zone configurations (single-face, multi-face, dead-end) so the chunk-selection retry path has options. Cover the 3×3 distribution (cells 3 and 4 wide) and 2×2 (cells 6 wide).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 castle.chunks and cave.chunks parse without errors.
- [ ] #2 Each theme has ≥1 deployment chunk for every cell dimension used by its distributions.
- [ ] #3 Each theme has enough non-deployment variety that a 3×3 map can generate without exhausting retry budgets for at least 95% of seeds in 0..99 (verified by spec).
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
