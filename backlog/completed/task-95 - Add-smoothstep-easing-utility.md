---
id: TASK-95
title: Add smoothstep easing utility
status: Done
assignee: []
created_date: '2026-05-08 04:31'
updated_date: '2026-05-08 04:34'
labels: []
milestone: m-15
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a `smoothstep(t)` function (`3t²−2t³`, input clamped to [0,1]) to a shared math utilities module. If no such module exists, create `src/tactics/math_util.lua` and return it as a plain table.

This will be used by the page flip animator to ease the curl progress over 40 frames.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Unit tests pass: smoothstep(0)==0, smoothstep(1)==1, smoothstep(0.5)==0.5, smoothstep(-1)==0, smoothstep(2)==1
- [x] #2 Output is monotonically increasing between 0 and 1
- [x] #3 `make test` passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
