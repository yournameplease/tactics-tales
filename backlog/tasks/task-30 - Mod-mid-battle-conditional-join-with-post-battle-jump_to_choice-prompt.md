---
id: TASK-30
title: 'Mod: mid-battle conditional join with post-battle jump_to_choice prompt'
status: To Do
assignee: []
created_date: '2026-04-26 19:12'
updated_date: '2026-04-26 20:09'
labels: []
milestone: m-6
dependencies: []
priority: medium
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Mod battle script pattern. A unit joins the player's side mid-battle as a temporary ally via existing battle script hooks. An end-of-battle script checks whether the survival or side objective condition was met; if so, the post-battle story sequence includes a jump_to_choice recruitment prompt (accept → roster_add, decline → continue). Quota credit is decremented when the prompt fires. Entirely mod Lua — no engine changes needed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A battle script pattern supports mid-battle unit join as temporary ally
- [ ] #2 End-of-battle script checks survival or side objective condition
- [ ] #3 If condition met, post-battle story sequence fires jump_to_choice prompt
- [ ] #4 Quota credit decremented when prompt fires
- [ ] #5 Player can accept or decline
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
