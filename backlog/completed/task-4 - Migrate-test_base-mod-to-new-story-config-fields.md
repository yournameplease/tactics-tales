---
id: TASK-4
title: Migrate test_base mod to new story config fields
status: Done
assignee: []
created_date: '2026-04-25 04:12'
updated_date: '2026-04-25 04:17'
labels: []
milestone: m-0
dependencies:
  - TASK-1
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Move `default_story` and `story_select` from `mods/test_base/game_data/stories.lua` (lines 130-131) into `content` in `mods/test_base/mod.lua`. Remove them from the stories file.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 mod.lua content has default_story and story_select with the same values that were in stories.lua
- [ ] #2 stories.lua ModStoriesModule only has data
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
