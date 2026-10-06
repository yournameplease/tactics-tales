---
id: TASK-150
title: Fix autotiler glyph mapping and add spawn_label_meta
status: Done
assignee: []
created_date: '2026-05-19 22:49'
updated_date: '2026-05-19 23:51'
labels: []
milestone: m-23
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Modify `src/tactics/battle/map/procgen/autotiler.lua` to support boss glyphs and fix a bug.

**Bug fix:** `g` currently maps to `"enemy_commander"` — change it to `"enemy_tank"`.

**New uppercase boss glyphs** in `SPAWN_LABELS`: `I→"enemy_infantry_boss"`, `R→"enemy_ranged_boss"`, `T→"enemy_tank_boss"`, `G→"enemy_tank_boss"`, `C→"enemy_commander_boss"`. Add all uppercase variants to `FLOOR_GLYPHS`.

**New `SPAWN_LABEL_META` constant** mapping every label to `{role, tags?}`:
- Normal roles: `{role="enemy_infantry"}` etc.
- Boss variants: `{role="enemy_infantry", tags={"boss"}}` etc. (role field uses the base role slot — `"enemy_infantry"`, not `"enemy_infantry_boss"`)
- `player_deployment`: `{role="player"}`

**`autotiler.build`** should populate `map.spawn_label_meta` (new field on BattleMap) from `SPAWN_LABEL_META`, keyed by each label that has at least one tile position.

`BattleMap` (`src/tactics/battle/battle_map.lua`) needs a `spawn_label_meta` field added to its type annotation and `new()` constructor.

**Acceptance criteria:**
- `make test` passes
- A map built from a glyph grid containing uppercase `G` has `tile_labels["enemy_tank_boss"]` with correct positions and `spawn_label_meta["enemy_tank_boss"] = {role="enemy_tank", tags={"boss"}}`
- A map with lowercase `g` produces `tile_labels["enemy_tank"]` (not `enemy_commander`)
- Uppercase boss glyphs render as floor tiles (tile id 1), not walls
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
