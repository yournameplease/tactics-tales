---
id: TASK-140
title: Glyph→BattleMap autotiler and tile-label collection
status: Done
assignee: []
created_date: '2026-05-17 00:41'
updated_date: '2026-05-17 02:22'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per spec §8 steps 12–14 and §9.2: build a fresh `BattleMap`, populate only the `ground` layer with tile id 1 for passable glyphs and tile id 2 for `#`. Collect spawn glyph positions into `tile_labels` per the §4.3 mapping (`enemy_infantry`, `enemy_ranged`, `enemy_tank`, `enemy_commander`, `player_deployment`). Other terrain layers and `spawn_groups`/`rect_zones` remain empty. Mod authors are responsible for tileset indices 1 (floor) and 2 (wall + solid flag).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Returns a BattleMap with width=16, height=16, ground layer populated, no other terrain layers set.
- [ ] #2 tile_labels contain exactly the points marked by spawn glyphs.
- [ ] #3 Glyphs `p` and `a` produce no tile labels in v1.
- [ ] #4 Spec verifies tile placement and label collection for a small hand-authored grid.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
