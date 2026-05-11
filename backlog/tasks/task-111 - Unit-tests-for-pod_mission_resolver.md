---
id: TASK-111
title: Unit tests for pod_mission_resolver
status: To Do
assignee: []
created_date: '2026-05-10 14:05'
updated_date: '2026-05-11 22:52'
labels: []
milestone: m-17
dependencies:
  - TASK-114
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Unit tests for `pod_mission_resolver` covering the rewritten resolver (TASK-114).

Test file: `mod_spec/tt_procedural_campaign/pod_mission_resolver_spec.lua` (or update existing).

Key scenarios to cover:
- Variant is selected by RNG from `meta.variant_sets`
- A `patrol` group spawns budget-sized unit count from its rect zone using the faction's `role_map` slot
- A `guard` group spawns exactly one unit (stationary AI) from its point zone regardless of budget
- A `boss` group spawns exactly one unit (stationary AI, tagged `"boss"`) from its point zone
- `threat_mult` scales per-group budget independently (`base_pod_budget × threat_mult`)
- Groups not listed in the selected variant do not spawn
- Authored `facing` is present on the emitted `UnitSpawnData`
- `ambush` role resolves to the correct slot via `role_map` (including fallback when slot absent)
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
