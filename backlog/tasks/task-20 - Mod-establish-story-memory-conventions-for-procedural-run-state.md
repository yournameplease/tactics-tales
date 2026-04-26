---
id: TASK-20
title: 'Mod: establish story memory conventions for procedural run state'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-3
dependencies: []
priority: high
ordinal: 3000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Story memory already supports arbitrary keys via set_memory nodes and factory functions. This task defines the memory key conventions the procedural mod uses: archetype_id, story_seed, battle_index, base_difficulty, faction_appearance_counts, recruitment_quota_credits, quota_window_counter, used_encounter_templates. Verify that story memory is fully persisted to save data and restored on load — if not, that is the only engine fix needed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Memory key conventions are defined and documented in the mod
- [ ] #2 Story memory is fully persisted to save data and restored on load (engine fix if needed)
- [ ] #3 All procedural state is readable from config.memory in factory functions and battle factories
- [ ] #4 Existing StoryConfig and story memory usage is unaffected
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
