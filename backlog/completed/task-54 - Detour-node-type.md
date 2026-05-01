---
id: TASK-54
title: Detour node type
status: Done
assignee: []
created_date: '2026-05-01 14:30'
updated_date: '2026-05-01 14:40'
labels:
  - needs-triage
dependencies: []
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add a `detour` campaign node type — analogous to Yarn Spinner's detour. A detour jumps to a named node, executes it fully, then implicitly returns to the original sequence at the step after the detour node.

**What to build:**
1. Add a `return_stack` field (array of `{node_id, node_step}`) to the `Campaign` object.
2. Register a `detour` handler in `src/tactics/campaign/handlers/node_handlers.lua`:
   - `enter`: push `{node_id = campaign.current_node.node_id, node_step = campaign.current_node.node_step + 1}` onto `return_stack`, then call `campaign:jump_to_node(node.target)`.
3. In `Campaign:advance_node()`, after incrementing `node_step`, check if `steps[node_step]` is nil. If so and `return_stack` is non-empty, pop the top entry and resume at that position (set `current_node` and call `handle_new_node`).
4. Add `campaigns.detour(target)` helper in `mods/base/game_data/campaigns.lua` returning `{type = "detour", target = target}`.
5. Add `"detour"` to the `CampaignNodeType` union in `src/tactics/campaign/types.lua`.
6. Add a `DetourNode` type: `{type: "detour", target: string}`.

**Detour semantics:** Detours are nestable — the return stack supports multiple levels. When a detoured node itself does a detour, the outer return point is preserved.

**Key files:**
- `src/tactics/campaign/campaign.lua` — `Campaign` struct, `advance_node`
- `src/tactics/campaign/handlers/node_handlers.lua` — handler registration
- `src/tactics/campaign/types.lua` — type annotations
- `mods/base/game_data/campaigns.lua` — `campaigns.detour` helper
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 DetourNode type and 'detour' CampaignNodeType are defined in types.lua
- [x] #2 Detour handler pushes correct return point and jumps to target node
- [x] #3 advance_node implicitly returns to the caller when a node's steps are exhausted and return_stack is non-empty
- [x] #4 Nested detours work correctly (outer return point is preserved across inner detour)
- [x] #5 campaigns.detour(target) helper returns the correct node table
- [x] #6 Unit or integration tests cover: basic detour return, nested detours, detour to a node that itself detours
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
