---
id: TASK-27
title: 'Mod: faction-tagged spawn slots and battle parameterization'
status: Done
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-27 02:25'
labels: []
milestone: m-5
dependencies: []
priority: high
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. `mods/tt_procedural_story/game_data/battles.lua` loads factions via `include()`, defines a `resolve_slot(faction, tier_index, slot_tag)` helper that selects the template from the correct tier (clamping to last tier if index exceeds length) and applies `faction.fallbacks` when a slot is absent. Encounter templates (filler battles) use this helper to build `character_source.template(...)` entries, reading `faction_id` and `base_difficulty` from `story_config.memory`. Existing static battles in `tt_fantasy_demo_story` are unaffected.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 resolve_slot helper defined in tt_procedural_story/game_data/battles.lua
- [x] #2 resolve_slot applies faction.fallbacks when slot absent from tier
- [x] #3 resolve_slot clamps to last tier when tier_index exceeds tier count
- [x] #4 Encounter templates use faction slot tags resolved at runtime via resolve_slot
- [x] #5 faction_id is readable by battle scripts via story_config.memory
- [x] #6 Existing static battles in tt_fantasy_demo_story are unaffected
- [x] #7 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
