---
id: TASK-65
title: Add base/lib/battle.lua — shared battle data factories
status: Done
assignee: []
created_date: '2026-05-03 19:24'
updated_date: '2026-05-03 19:54'
labels: []
milestone: m-12
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Three mods independently redefine `character_source.template()`, `character_source.player_roster()`, `objectives.rout()`, and similar factories. AI preset tables also overlap significantly between `tt_fantasy_demo_story` and `tt_procedural_campaign`. Extract into `base/lib/battle.lua` (or `tactics_puzzler/lib/`) exposing: `lib.libs.battle.character_source.*`, `lib.libs.battle.victory.*`, `lib.libs.battle.failure.*`, and a canonical AI preset table. Mods drop their local redefinitions. This pairs naturally with the Mission rename task (task for BattleDefinition → MissionDefinition).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 base/lib/battle.lua (or equivalent) registered in mod sandbox
- [x] #2 character_source, victory, failure constructors available via lib.libs.battle
- [x] #3 AI preset table standardized and shared
- [x] #4 Local copies removed from all mods
- [x] #5 Tests pass
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
