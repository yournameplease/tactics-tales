---
id: TASK-90
title: Add unit tests for campaign node handlers
status: To Do
assignee: []
created_date: '2026-05-05 13:19'
labels: []
milestone: m-14
dependencies: []
references:
  - src/tactics/campaign/campaign.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Campaign node handlers have zero unit test coverage. Story nodes (text, battle, jump, state-branch, roster-add, etc.) are the primary authoring surface for mods. Handler bugs silently corrupt Campaign State or skip branches; the only current coverage is via happy-path mod integration tests.

Write unit tests for each handler type using simple Campaign State fixtures. Focus on state mutation isolation and branch condition evaluation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Each handler type has at least one test (text, battle, jump, state_branch, roster_add / recruit)
- [ ] #2 State mutations from one handler do not affect a sibling handler's inputs
- [ ] #3 state_branch: correct branch selected when condition is true; alternate branch when false
- [ ] #4 Malformed node definition produces a clear error rather than silent failure
- [ ] #5 Existing passing tests remain green
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
