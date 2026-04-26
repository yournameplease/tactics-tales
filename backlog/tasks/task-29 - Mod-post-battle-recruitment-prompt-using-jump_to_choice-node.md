---
id: TASK-29
title: 'Mod: post-battle recruitment prompt using jump_to_choice node'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-6
dependencies: []
priority: high
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Implemented in mod Lua using the engine's jump_to_choice node (added as a separate engine task in m-6). The post-battle story sequence presents a recruitment offer: accept jumps to a roster_add node then continues; decline jumps directly to the continue node. Both paths spend the quota credit (decremented in story memory before the prompt fires). No new story node type needed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Post-battle recruitment is wired using jump_to_choice + roster_add nodes
- [ ] #2 Accept branch adds the character to the roster
- [ ] #3 Decline branch skips the join
- [ ] #4 Quota credit is decremented before the prompt fires (spent on opportunity)
- [ ] #5 Pattern is usable in both procedural and static stories
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
