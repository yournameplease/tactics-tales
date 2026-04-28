---
id: TASK-29
title: 'Mod: implement auto_recruit_pending post-battle manager node'
status: Done
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-28 01:10'
labels: []
milestone: m-6
dependencies:
  - TASK-40
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Factory function in mods/tt_procedural_story/game_data/stories.lua. Runs after each battle as a manager node.

Initial implementation (turncoat_enemy only):
- Reads pending_recruits list from story memory
- Shows "[auto_recruit] Pending recruits processed: {list}." debug text line
- Clears pending_recruits from story memory (writes empty list)

Future extension points (not implemented now):
- surprise_reinforcements: auto-join via roster_add if not recruited mid-battle
- wanderer fallback: roster_add from wanderer_pool

Files: mods/tt_procedural_story/game_data/stories.lua
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Reads pending_recruits list from story memory after battle
- [ ] #2 Shows debug text line with list contents
- [ ] #3 Clears pending_recruits in story memory
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
