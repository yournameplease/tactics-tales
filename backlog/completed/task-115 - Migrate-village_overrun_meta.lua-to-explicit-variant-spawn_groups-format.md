---
id: TASK-115
title: Migrate village_overrun_meta.lua to explicit variant spawn_groups format
status: Done
assignee: []
created_date: '2026-05-11 22:52'
updated_date: '2026-05-11 23:46'
labels: []
milestone: m-17
dependencies:
  - TASK-114
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Rewrite `mods/tt_procedural_campaign/game_data/maps/village_overrun_meta.lua` to use the explicit `spawn_groups` format consumed by the updated resolver.

**Map zones available:**
- Rect zones (pods): `pod_w`, `pod_e`, `pod_nw`, `pod_sw`, `pod_se`, `pod_s`, `pod_n_wall`, `pod_s_wall`
- Point zones (guards): `house_n_guard`, `house_w_guard`, `house_e_guard`
- Point zones (bosses): `boss_sw`, `boss_se`, `boss_ne`
- Deployment rects: `deployment_w`, `deployment_n`, `deployment_e`

Replace `excludes` lists with explicit `spawn_groups` per variant. Each group needs `zone`, `role`, `facing`, and optionally `threat_mult`. Groups not listed in a variant do not spawn.

Note: `house_n_guard`, `house_w_guard`, `house_e_guard` are point zones that the old resolver never picked up (wrong prefix). Include them now as `role = "guard"` groups with appropriate facing per variant.

Remove the `excludes` field entirely — it is superseded by the explicit listing.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 variant_sets entries have spawn_groups, not excludes
- [x] #2 All three variants (deployment_w, deployment_e, deployment_n) are covered
- [x] #3 house guards included as guard-role groups with facing
- [x] #4 No zone appears in a variant where it would overlap the deployment area
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
