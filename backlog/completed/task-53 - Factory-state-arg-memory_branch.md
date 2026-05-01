---
id: TASK-53
title: Factory state arg + memory_branch
status: Done
assignee: []
created_date: '2026-05-01 14:30'
updated_date: '2026-05-01 14:33'
labels:
  - needs-triage
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Campaign node factory functions currently receive `(campaign_config, rng_context)`. We need to pass a third argument — a flat snapshot of campaign state — so that factories can branch on runtime state (not just config).

**What to build:**
1. In `src/tactics/campaign/campaign.lua`, change `resolve_node_source` and `resolve_to_array` to pass `self.campaign_state:get_as_map()` as a third argument when calling factory functions.
2. Update the `StoryNodeFactory` LuaCATS type annotation to `fun(config: StoryConfig, rng: StoryRngContext, state: table<string, string>): StoryNodeSource`.
3. In `mods/base/lib/story.lua`, add `story.memory_branch(predicate, node_if_true, node_if_false)` — analogous to `config_branch` but the predicate receives `(config, state)`. Returns a `StoryNodeFactory`.
4. The existing `config_branch` function is backwards-compatible (it ignores extra args) — no changes needed there.

**Key files:**
- `src/tactics/campaign/campaign.lua` — `resolve_node_source` (line ~72), `resolve_to_array` (line ~85)
- `mods/base/lib/story.lua` — add `memory_branch` alongside `config_branch`
- `src/tactics/campaign/types.lua` — `StoryNodeFactory` type
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 resolve_node_source and resolve_to_array pass campaign_state:get_as_map() as third arg to factory functions
- [x] #2 StoryNodeFactory type annotation updated to include the state map parameter
- [x] #3 story.memory_branch(predicate, node_if_true, node_if_false) exists in mods/base/lib/story.lua
- [x] #4 memory_branch predicate receives (config, state_map) and returns the correct node branch
- [x] #5 Existing config_branch usage in the codebase is unaffected
- [x] #6 Unit tests cover memory_branch branching on state values
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
