---
id: TASK-21
title: 'Engine: seedable RNG class and story runner integration'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-4
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Engine work in two parts:

1. Add `random.new(seed)` to `src/tactics/util/random.lua` — a pure Lua RNG instance (xorshift or LCG) with its own state, independent of Picotron's global srand/rnd. Supports rndi, choose_random_from_list, etc. on the instance.

2. Story runner creates a story-level RNG at run start (seed auto-generated from global RNG and persisted in save data). Before each battle, derives a battle-level seed deterministically from story_seed + battle_index and creates a battle-level RNG instance. Both instances are passed via StoryConfig to all factory functions and battle factories.

Mod Lua uses these instances for all procedural decisions and does not call the global RNG.

Hot areas: `src/tactics/util/random.lua`, story runner (story execution management).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 random.new(seed) returns an independent RNG instance with its own state
- [ ] #2 Instance API matches existing random module (rndi, choose_random_from_list, etc.)
- [ ] #3 Story seed is auto-generated at run start and persisted in save data
- [ ] #4 Battle seed is derived deterministically from story_seed + battle_index
- [ ] #5 Both RNG instances are accessible via StoryConfig in factory functions
- [ ] #6 Loading a save and re-running produces identical future sequences
- [ ] #7 Existing global RNG usage is unaffected
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
