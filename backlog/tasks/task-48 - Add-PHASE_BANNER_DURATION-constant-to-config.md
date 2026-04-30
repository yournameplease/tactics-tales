---
id: TASK-48
title: Add PHASE_BANNER_DURATION constant to config
status: To Do
assignee: []
created_date: '2026-04-30 03:19'
updated_date: '2026-04-30 03:19'
labels: []
milestone: m-10
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `PHASE_BANNER_DURATION = 90` to `STATIC_CONFIG` in `src/tactics/config.lua`. This constant controls how many frames the phase banner is displayed (90 frames ≈ 1.5 seconds at 60fps). Also add the field to the `StaticConfig` LuaCATS annotation.\n\nAcceptance:\n- `STATIC_CONFIG.PHASE_BANNER_DURATION` exists and equals `90`\n- `StaticConfig` LuaCATS class annotation includes the field
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->



## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 STATIC_CONFIG.PHASE_BANNER_DURATION exists and equals 90
- [ ] #2 StaticConfig LuaCATS class annotation includes the PHASE_BANNER_DURATION field
<!-- AC:END -->
