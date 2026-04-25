---
id: TASK-2
title: Read story_select and default_story from mod spec in mod_loader
status: Done
assignee: []
created_date: '2026-04-25 04:12'
updated_date: '2026-04-25 04:17'
labels: []
milestone: m-0
dependencies:
  - TASK-1
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
In `src/tactics/mods/mod_loader.lua`, update `load_mod_data()` to read `story_select` and `default_story` directly from `mod.spec.content` instead of loading them from the stories data file via `load_mod_val`.

- `story_select`: last-wins across registered mods; if no mod sets it, default to all keys of `stories.data`
- `default_story`: last-wins; error if no mod sets it ("No default_story defined in any mod's content")

Check the `fp`/`maps`/`lists` utility modules for an existing keys-of-table helper before writing new code.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 story_select and default_story are read from mod.spec.content, not from the stories data file
- [ ] #2 Omitting story_select in all mods causes all story IDs to be shown
- [ ] #3 Omitting default_story in all mods causes a runtime error
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
