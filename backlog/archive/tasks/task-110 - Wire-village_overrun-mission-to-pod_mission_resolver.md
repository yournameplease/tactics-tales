---
id: TASK-110
title: Wire village_overrun mission to pod_mission_resolver
status: To Do
assignee: []
created_date: '2026-05-10 14:04'
updated_date: '2026-05-10 14:05'
labels: []
milestone: m-17
dependencies:
  - TASK-109
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Replace the hardcoded `village_overrun` entry in `mods/tt_procedural_campaign/game_data/missions.lua` with a thin wrapper that loads the meta file and delegates to `build_pod_mission`. Depends on TASK-109.

```lua
["village_overrun"] = function(campaign_config, rng_context, map_context)
    local meta = include("mods/tt_procedural_campaign/game_data/maps/village_overrun_meta.lua")
    return build_pod_mission(campaign_config, rng_context, map_context, meta)
end,
```

No zone names, slot names, or budget constants should remain in missions.lua for this entry. The meta file (`village_overrun_meta.lua`) is unchanged.
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
