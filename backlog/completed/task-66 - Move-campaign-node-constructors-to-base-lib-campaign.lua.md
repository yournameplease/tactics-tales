---
id: TASK-66
title: Move campaign node constructors to base/lib/campaign.lua
status: Done
assignee: []
created_date: '2026-05-04 00:05'
updated_date: '2026-05-04 00:13'
labels: []
milestone: m-12
dependencies: []
references:
  - mods/tt_fantasy_demo_story/game_data/campaigns.lua
  - mods/base/lib/campaign.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
The ~15 campaign node constructor functions currently defined as locals in `tt_fantasy_demo_story/game_data/campaigns.lua` (lines 13–130) have no shared home — a new mod building a Campaign must copy them or depend on the fantasy mod for the wrong reason. Move all constructors into `base/lib/campaign.lua` alongside the existing `config_branch`, `detour` functions so that `lib.libs.campaign` is to Campaign authoring what `lib.libs.script` is to Battle Script authoring.

## Design decisions

**Renames (align with domain language and reduce redundancy):**

| Old | New | Reason |
|---|---|---|
| `campaign_text(t)` | `text(t)` | Drop redundant "campaign" prefix |
| `roster_add(template, tags)` | `recruit(template, tags)` | Domain term: Recruitment |
| `battle(id, v, f)` | `start_battle(id, {victory=v, failure=f})` | Mission=spec, Battle=instance; named table makes branches explicit |
| `set_memory(k, v)` | `set_state(k, v)` | Aligns with "Campaign State" domain term |
| `memory_branch(pred, t, f)` | `state_branch(pred, t, f)` | Rename existing function for consistency with set_state |
| `select_option(opts, memory_key)` | `select_option(opts, state_key)` | Parameter rename only |

**Unchanged names:** `new_page`, `chapter_header`, `save_game`, `delete_file`, `advance`, `exit_campaign`, `game_results`, `character_customizer`, `text_input`, `jump`, `detour`, `static_battle_config`, `chapter_debug`

**Structure:** All constructors flat on `campaign.*` — no sub-namespaces, no chainable builder pattern (consistent with `script.lua`).

**`character_customizer`, `chapter_debug`, and `static_battle_config`** are generic enough to live in base lib. `chapter_debug` is a dev utility for building a single-battle MissionDefinition for quick testing — useful to any mod author.

## Calling-code impact

`tt_fantasy_demo_story/game_data/campaigns.lua` currently holds the constructor locals. After the move it should drop its local constructor block entirely and call `lib.libs.campaign.*` throughout. All rename decisions above must be applied to the call sites in `campaigns.lua` as well.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 All constructors listed in the design decisions table are available via lib.libs.campaign with their new names
- [x] #2 memory_branch renamed to state_branch in base/lib/campaign.lua; all callers updated
- [x] #3 start_battle uses a named table for victory/failure branches: start_battle(id, {victory=node, failure=node})
- [x] #4 tt_fantasy_demo_story/game_data/campaigns.lua drops its local constructor block and delegates entirely to lib.libs.campaign
- [x] #5 A new mod can build a full campaign (prologue, battle node, victory/defeat branches, exit) using only lib.libs.campaign without requiring tt_fantasy_demo_story
- [x] #6 Tests cover each node constructor shape (return table structure and field values)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
