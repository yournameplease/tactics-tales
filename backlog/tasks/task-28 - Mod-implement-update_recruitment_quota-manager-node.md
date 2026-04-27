---
id: TASK-28
title: 'Mod: implement update_recruitment_quota manager node'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-27 13:40'
labels: []
milestone: m-6
dependencies:
  - TASK-40
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Factory function in mods/tt_procedural_story/game_data/stories.lua. Runs between battles as a manager node.

Logic:
- Reads recruitment_quota_credits (text memory, default 0) and the current archetype's recruitment_rate
- Adds rate to credits; takes floor(credits) as recruit count; carries remainder
- For each recruit, rolls a recruitment archetype type from the current encounter template's supported list (read from battles_meta.lua via story_config)
- Writes updated recruitment_quota_credits (text) and pending_recruits (list) back to story memory
- Shows "[quota] Added {rate} credits. {n} recruit(s) pending: {types}." debug text line

No window counter. Credits are spent at generation time (not on player acceptance).

Files: mods/tt_procedural_story/game_data/stories.lua, mods/tt_procedural_story/game_data/battles_meta.lua
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Credits accumulate by recruitment_rate each battle; fractional remainder carries forward
- [ ] #2 floor(credits) recruits are rolled per battle
- [ ] #3 Each recruit's archetype is drawn from the encounter template's supported list in battles_meta.lua
- [ ] #4 pending_recruits written as list memory entry; recruitment_quota_credits written as text entry
- [ ] #5 Debug text line shown during node execution
- [ ] #6 No window counter logic
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
