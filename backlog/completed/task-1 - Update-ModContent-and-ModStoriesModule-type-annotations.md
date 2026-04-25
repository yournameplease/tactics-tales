---
id: TASK-1
title: Update ModContent and ModStoriesModule type annotations
status: Done
assignee: []
created_date: '2026-04-25 04:12'
updated_date: '2026-04-25 04:17'
labels: []
milestone: m-0
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `story_select? string[]` and `default_story? string` to `ModContent` in `mods/types.d.lua`. Remove both fields from `ModStoriesModule` — it should only retain `data`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ModContent has story_select? string[] and default_story? string fields
- [ ] #2 ModStoriesModule only has the data field
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
