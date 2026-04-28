---
id: TASK-31
title: 'Mod: forced join using existing roster_add node'
status: Done
assignee: []
created_date: '2026-04-26 19:12'
updated_date: '2026-04-28 01:38'
labels: []
milestone: m-6
dependencies: []
priority: medium
ordinal: 4000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
roster_add already exists as a story node. This task is a mod battle script and story pattern: a battle script fires at the appropriate moment (or the post-battle story sequence runs directly), and roster_add adds the character with no player prompt. No engine changes needed. Quota credits are not consumed for forced joins.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Forced join is implemented using the existing roster_add story node
- [x] #2 No player prompt is shown
- [x] #3 Quota credits are not consumed
- [x] #4 Pattern works in both beat and filler slots
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
