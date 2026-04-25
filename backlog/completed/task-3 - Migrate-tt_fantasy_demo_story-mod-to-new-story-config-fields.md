---
id: TASK-3
title: Migrate tt_fantasy_demo_story mod to new story config fields
status: Done
assignee: []
created_date: '2026-04-25 04:12'
updated_date: '2026-04-25 04:17'
labels: []
milestone: m-0
dependencies:
  - TASK-1
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Move `default_story` and `story_select` from `mods/tt_fantasy_demo_story/game_data/stories.lua` (lines 503-516) into `content` in `mods/tt_fantasy_demo_story/mod.lua`. Remove them from the stories file.
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
