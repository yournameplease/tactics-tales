---
id: TASK-5
title: Update mod_loader_spec for new story config source
status: Done
assignee: []
created_date: '2026-04-25 04:12'
updated_date: '2026-04-25 04:17'
labels: []
milestone: m-0
dependencies:
  - TASK-2
  - TASK-3
  - TASK-4
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update `src/spec/mods/mod_loader_spec.lua` to reflect the new structure:
- Move `default_story` and `story_select` from the stories file fixture into the mod spec `content` table
- Add test: `story_select` omitted by all mods → `story_ids` contains all story keys
- Add test: `default_story` omitted by all mods → error is raised
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Existing validate_mods test passes with fields moved to mod spec
- [ ] #2 New test confirms story_select defaults to all stories when omitted
- [ ] #3 New test confirms error is raised when default_story is omitted
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
