---
id: TASK-30
title: 'Mod: add turncoat recruit slot and interaction script to skirmish template'
status: Done
assignee: []
created_date: '2026-04-26 19:12'
updated_date: '2026-04-28 01:14'
labels: []
milestone: m-6
dependencies:
  - TASK-28
priority: medium
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Modify the skirmish battle factory in mods/tt_procedural_story/game_data/battles.lua.

- Add a recruit_slot tile label to the skirmish battle config (playground map must expose a suitable tile)
- On battle generation, read pending_recruits list from story_config.memory
- If pending_recruits contains "turncoat_enemy":
  - Pick a random template from faction.recruitable (slot tags resolved against current tier)
  - Spawn unit at recruit_slot with side="enemy"
  - Add an on_unit_interaction script: any adjacent player unit talks → "[turncoat] Turncoat joins the player." dialogue → recruit_unit(trigger_target)
- Otherwise: spawn a normal enemy unit (enemy_infantry) at recruit_slot

Files: mods/tt_procedural_story/game_data/battles.lua, mods/base/lib/script.lua (verify on_unit_interaction builder exists)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 recruit_slot tile is declared in skirmish battle config
- [ ] #2 When pending_recruits contains turncoat_enemy, a recruitable unit spawns at recruit_slot as enemy with interaction script
- [ ] #3 Talking to the unit triggers dialogue then immediately recruits them (no yes/no prompt)
- [ ] #4 When pending_recruits does not contain turncoat_enemy, a normal enemy spawns at recruit_slot
- [ ] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
