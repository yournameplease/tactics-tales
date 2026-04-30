---
id: DRAFT-1
title: Add on_battle_end script trigger
status: Draft
assignee: []
created_date: '2026-04-30 22:25'
labels:
  - battle-scripts
  - needs-design
dependencies: []
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add an `on_battle_end` trigger type for Battle Scripts, firing after a battle concludes. Requires design discussion before implementation.

Key questions to resolve:
- What context is passed to the script? At minimum, each unit's survival status should be available (which units survived, which died this battle).
- Should the trigger fire on both victory and defeat, or only one? Or should it be filterable?
- How does this interact with the battle result (victory/failure condition that triggered end)?
- Execution timing: does this fire before or after the BATTLE_END event and story node transition?
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
