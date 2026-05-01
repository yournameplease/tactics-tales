---
id: TASK-55
title: Stats text substitution
status: Done
assignee: []
created_date: '2026-05-01 14:30'
updated_date: '2026-05-01 14:44'
labels:
  - needs-triage
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Extend the campaign text replacement system to expose battle statistics via `${stats.N.*}` and `${stats.current.*}` tokens, so story text nodes can reference outcomes like unit death counts.

**What to build:**
Serialize per-chapter stats into the replacement map used by the dialogue manager. The map is currently built from `campaign_state:get_as_map()`. Stats should be merged in alongside campaign state entries.

**Keys to serialize** (for each chapter N with a recorded result in `stats_service.story_results.chapter_results`):
- `stats.N.units_lost` — string representation of `#chapter_results[N].units_lost`
- `stats.N.turns_taken` — string representation of `chapter_results[N].turns_taken`

Additionally, serialize `stats.current.*` pointing to the highest-indexed chapter present in `chapter_results`:
- `stats.current.units_lost`
- `stats.current.turns_taken`

**Where to add this:** The text node handler calls `campaign.dialogue_manager:create_dialogue(text, campaign.campaign_state:get_as_map())`. Either extend `get_as_map()` to accept supplementary entries, or merge a stats map at the call site in the handler.

**Key files:**
- `src/tactics/campaign/handlers/node_handlers.lua` — text node handler
- `src/tactics/campaign/statistics/stats_service.lua` — `story_results` access
- `src/tactics/campaign/statistics/campaign_statistics.lua` — `StoryChapterResult` type
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 ${stats.N.units_lost} in story text resolves to the count of units lost in chapter N
- [x] #2 ${stats.N.turns_taken} resolves to turns taken in chapter N
- [x] #3 ${stats.current.units_lost} and ${stats.current.turns_taken} resolve to the highest-indexed chapter's values
- [x] #4 stats.current.* is absent (or blank) if no battles have completed yet
- [x] #5 Existing ${hero.name} and other campaign state substitutions are unaffected
- [x] #6 Unit tests cover serialization with 0, 1, and multiple chapters recorded
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
