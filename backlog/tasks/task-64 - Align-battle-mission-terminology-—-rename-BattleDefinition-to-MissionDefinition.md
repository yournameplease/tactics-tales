---
id: TASK-64
title: >-
  Align battle/mission terminology — rename BattleDefinition to
  MissionDefinition
status: To Do
assignee: []
created_date: '2026-05-03 19:24'
labels: []
milestone: m-12
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The domain model defines **Mission** as "the authored setup for a single battle," but the code surface uses `BattleDefinition`, `BattleDefinitionFactory`, and the game-data key `battles`. Rename to align: `BattleDefinition` → `MissionDefinition`, `BattleDefinitionFactory` → `MissionFactory`, game-data key `battles` → `missions`. Add a deprecation alias during transition if needed. This affects `src/tactics/mods/mod_schema.lua`, `game_data.lua`, and all mod `game_data/battles.lua` files.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 mod_schema.lua uses 'missions' key
- [ ] #2 game_data.lua GameData type uses missions field
- [ ] #3 All mods renamed game_data/battles.lua to game_data/missions.lua (or key updated)
- [ ] #4 LuaCATS types updated throughout
- [ ] #5 Tests pass
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
