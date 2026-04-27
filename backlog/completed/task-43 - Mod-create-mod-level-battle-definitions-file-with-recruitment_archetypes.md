---
id: TASK-43
title: 'Mod: create mod-level battle definitions file with recruitment_archetypes'
status: Done
assignee: []
created_date: '2026-04-27 13:41'
updated_date: '2026-04-27 13:56'
labels: []
milestone: m-6
dependencies: []
priority: high
ordinal: 700
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create a new file mods/tt_procedural_story/game_data/battles_meta.lua that declares static metadata about each encounter template — specifically which recruitment archetypes the template's map layout supports.

Data shape:
  battles_meta[template_id] = { recruitment_archetypes: string[] }

Initial content:
  skirmish → { recruitment_archetypes = {"turncoat_enemy"} }

This file is read by update_recruitment_quota to determine which archetype types to roll when injecting recruits into a battle. Templates that declare no recruitment_archetypes trigger the post-battle wanderer fallback.

LuaCATS type: BattleMetaEntry with field recruitment_archetypes: string[].

Files: mods/tt_procedural_story/game_data/battles_meta.lua (new)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 battles_meta.lua exists and returns a table keyed by template ID
- [ ] #2 skirmish entry declares recruitment_archetypes = {"turncoat_enemy"}
- [ ] #3 BattleMetaEntry type is annotated with LuaCATS
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
