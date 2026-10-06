---
id: TASK-73
title: Skill system design session
status: Done
assignee: []
created_date: '2026-05-04 21:48'
updated_date: '2026-05-04 22:29'
labels: []
milestone: m-13
dependencies: []
documentation:
  - docs/adr/skill-system.md
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Design session with user to fully specify the mod-configurable Skill system. Output: spec doc at docs/adr/skill-system.md and implementation task cards.\n\nPre-session decisions already settled:\n- Skills defined entirely in mod data (no hardcoded skills in engine)\n- Known Skills list on Character (persistent); cooldown + uses-remaining state on Unit (battle-instance)\n- Two resource models: turn-based cooldown and per-battle use limit (both supported)\n- HP cost allowed; self-kill from cost is allowed\n- Healing: separate action, targets one adjacent ally, no Combat exchange\n- Damaging: initiates Combat exchange, no counterattack, true damage (ignores defense)\n\nSession should resolve: mod data schema for Skill definitions, how Skills surface in the battle action menu, targeting API, animation/feedback hooks, and edge cases not yet settled.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 docs/adr/skill-system.md written and agreed with user
- [x] #2 Implementation tasks created from spec
- [x] #3 All pre-session decisions reflected in spec doc
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
