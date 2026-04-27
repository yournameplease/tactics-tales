---
id: TASK-42
title: 'Mod: add wanderer_pool to archetype definitions'
status: Done
assignee: []
created_date: '2026-04-27 13:41'
updated_date: '2026-04-27 13:56'
labels: []
milestone: m-6
dependencies: []
priority: medium
ordinal: 600
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a wanderer_pool field to ArchetypeDefinition in mods/tt_procedural_story/game_data/archetypes.lua.

- wanderer_pool is a flat list of character template ID strings (equal probability, no weights)
- Used as the unit source for neutral recruit archetypes (neutral_under_attack, surprise_reinforcements) and the post-battle wanderer fallback when no recruitment archetypes are supported by the current encounter template
- Warband archetype: populate with placeholder templates from tt_fantasy_demo_story (e.g. bandit_goon, militia_spearman) until dedicated wanderer templates exist
- Update ArchetypeDefinition LuaCATS annotation to include the new field

Files: mods/tt_procedural_story/game_data/archetypes.lua
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ArchetypeDefinition type annotation includes wanderer_pool: string[]
- [ ] #2 Warband archetype has a non-empty wanderer_pool with placeholder templates
- [ ] #3 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
