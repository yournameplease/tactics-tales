---
id: TASK-28
title: 'Mod: recruitment quota credit accumulation and window enforcement'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-6
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. recruitment_quota_credits and quota_window_counter live in story memory. After each battle, a hub node accumulates credits by the archetype's configured rate (default ~1.5). When credits >= 1, the quota_window_counter begins tracking. If no recruitment has fired within the configured window (default 2 battles), the next filler slot forces a recruitment. Credits are spent on the opportunity regardless of player outcome. No engine involvement.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Credits accumulate at configurable rate in story memory after each battle
- [ ] #2 quota_window_counter increments when credits >= 1 but no recruitment fired
- [ ] #3 Window threshold is configurable (default 2)
- [ ] #4 When window exceeded, choose_next_story_beat forces a recruitment filler slot
- [ ] #5 Credits are spent on opportunity creation, not on player acceptance
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
