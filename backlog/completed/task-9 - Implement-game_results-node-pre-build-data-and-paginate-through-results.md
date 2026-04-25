---
id: TASK-9
title: 'Implement game_results node: pre-build data and paginate through results'
status: Done
assignee: []
created_date: '2026-04-25 16:02'
updated_date: '2026-04-25 17:13'
labels: []
milestone: m-1
dependencies: []
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implement the full `game_results` story node: pre-build all display data at enter time and paginate through one chapter page then one unit page per confirm press.

**Screens:**
- Per-battle: chapter number, VICTORY/DEFEAT result, turns taken, list of names of units lost
- Per-unit: portrait (DrawableCharacterInstance), unit name, chapter recruited, #combats, #kills (derived)

**Enter logic** (in `game_results` handler, `node_handlers.lua`):
1. Call `story.character_manager:get_full_roster()` to get all units including dead, in recruitment order
2. For each unit, build a pre-computed struct: `{ drawable: DrawableCharacterInstance, name, chapter_recruited, combats, kills }`
   - `drawable`: build via `drawable_character.create_drawable_unit` (same pattern as `character_customization` handler)
   - `kills`: count appearances of `unit.id` as `attacker_id` across all `chapter_results[n].units_lost`
   - `combats`: `stats_service.story_results.unit_combats[unit.id] or 0`
   - `chapter_recruited`: `stats_service.story_results.chapter_recruited[unit.id]`
3. For units_lost names on per-battle screen: resolve `unit_id` → name via `character_manager:get_character()`
4. Store all pre-built data in the `RenderedGameResults` node (extend the type as needed in `story_page.lua`)

**Update logic** (custom, replacing `dialogue_update`):
- On confirm: if on chapters section and more chapter pages remain → increment `page`
- On confirm: if on last chapter page → switch to `section = "units"`, `page = 1`
- On confirm: if on units section and more unit pages remain → increment `page`
- On confirm: if on last unit page → call `story:advance_node()`
- Total pages: `#chapter_results` chapter pages + `#full_roster` unit pages

Files to modify:
- `src/tactics/story/story_page.lua` — extend `RenderedGameResults` type with pre-built unit and chapter display data
- `src/tactics/story/handlers/node_handlers.lua` — replace stub `game_results` handler with full enter + update implementation
- `src/tactics/story/statistics/story_statistics.lua` — if new types are needed for pre-built structs

Dependencies: tasks for chapter_recruited, UNIT_COMBAT, and get_full_roster should be complete first.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Adding a game_results node to the end of a story with completed battles shows one page per chapter (chapter number, result, turns, lost unit names) then one page per roster unit (portrait, name, chapter recruited, combats, kills).
- [x] #2 Confirm on the last unit page advances the story to the next node.
- [x] #3 Dead roster units appear on the unit screen.
- [x] #4 Kills are correctly derived from attacker_id in death records.
- [x] #5 Spec file covers enter pre-build logic and pagination update logic.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
