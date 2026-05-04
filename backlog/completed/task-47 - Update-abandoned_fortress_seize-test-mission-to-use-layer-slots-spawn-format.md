---
id: TASK-47
title: Update abandoned_fortress_seize test mission to use layer/slots spawn format
status: Done
assignee: []
created_date: '2026-04-28 03:10'
updated_date: '2026-05-04 15:00'
labels: []
milestone: m-9
dependencies:
  - TASK-45
  - TASK-46
priority: high
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
TASK-46 delivered `map.spawn_groups` populated directly from Tiled object layers and the `layer/slots` unit entry format in `tactics_engine`. The `.spawn.lua` file approach and `active_labels`/`active_variants` map-loader filtering are no longer needed.\n\nThe only remaining work is updating the `abandoned_fortress_seize` test mission in `mods/test_tt_procedural_campaign/` to use the new `layer/slots` format instead of the old `tile` + `active_labels` approach.\n\n**Slot keys for this map:**\n- `deployment_seize` — all points have no slot property → key is `"default"`\n- `boss_seize` — layer-level `slot = "enemy_commander"` → key is `"enemy_commander"`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 abandoned_fortress_seize mission uses layer/slots format referencing deployment_seize and boss_seize spawn groups
- [x] #2 active_labels field and tile-label unit entries are removed from the mission
- [x] #3 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
