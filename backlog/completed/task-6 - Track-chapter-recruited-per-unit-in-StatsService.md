---
id: TASK-6
title: Track chapter recruited per unit in StatsService
status: Done
assignee: []
created_date: '2026-04-25 16:02'
updated_date: '2026-04-25 17:07'
labels: []
milestone: m-1
dependencies: []
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a `chapter_recruited: table<UnitId, integer>` map to `StatsService` and populate it from the `roster_add` node handler.

Files to modify:
- `src/tactics/story/statistics/story_statistics.lua` — add `chapter_recruited` to `StoryStatistics` type (or directly on `StoryResults`)
- `src/tactics/story/statistics/stats_service.lua` — add `chapter_recruited` map to `story_results`, add a `record_recruitment(unit_id, chapter)` method
- `src/tactics/story/handlers/node_handlers.lua` — in the `roster_add` handler `enter`, call `story.stats_service:record_recruitment(created.id, story.story_page.chapter_number)` after persisting the character

Note: `story.story_page.chapter_number` is set by `clear_chapter_header` and reflects the current chapter at time of recruitment.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 After a roster_add node fires in a story with a chapter_header, stats_service.story_results.chapter_recruited[unit_id] equals the chapter number at time of recruitment.
- [x] #2 The chapter_recruited map is included in serialized save data (StoryResults is already serialized wholesale — verify no extra work needed).
- [x] #3 Unit tests cover record_recruitment and verify the map is populated correctly.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
