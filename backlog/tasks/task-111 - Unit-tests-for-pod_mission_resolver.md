---
id: TASK-111
title: Unit tests for pod_mission_resolver
status: To Do
assignee: []
created_date: '2026-05-10 14:05'
updated_date: '2026-05-10 14:05'
labels: []
milestone: m-17
dependencies:
  - TASK-109
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Write Busted specs for `mods/tt_procedural_campaign/lib/pod_mission_resolver.lua`. Depends on TASK-109.

Test file: `build/spec/mods/tt_procedural_campaign/lib/pod_mission_resolver_spec.lua`

Cases to cover:
- Active variant is selected and excludes are applied (excluded zones produce no unit entries)
- `pod_*` zones generate enemy units with a non-commander slot and budget-capped count
- `guard_*` point zones generate stationary enemy_tank units, one per point
- `boss_*` point zones generate enemy_commander units, one per point
- Player deploy points are drawn from the active variant's deployment zone
- A pod zone in the excludes list is skipped entirely
- Zero active pods (budget division edge case) does not error
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
