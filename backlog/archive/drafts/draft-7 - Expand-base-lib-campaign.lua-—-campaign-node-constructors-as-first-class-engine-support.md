---
id: DRAFT-7
title: >-
  Expand base/lib/campaign.lua — campaign node constructors as first-class
  engine support
status: Draft
assignee: []
created_date: '2026-05-03 19:24'
labels: []
milestone: m-12
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
~15 campaign node constructor functions (dialogue page, chapter header, save-game, battle node, recruit, etc.) are defined as locals inside `tt_fantasy_demo_story/game_data/campaigns.lua` (lines 13–130). A new mod building a Campaign has no shared source for these — it must copy from the fantasy mod or depend on it for the wrong reason. Move all node constructors into `base/lib/campaign.lua` alongside the existing `config_branch`, `memory_branch`, `detour` functions. `lib.libs.campaign` should be to Campaign authoring what `lib.libs.script` is to Battle Script authoring.

**Needs design discussion before implementation**: Which node types belong in base vs. in a mod? Are any node constructors fantasy-story-specific? Should the builder be chainable (like ScriptBuilder) or stay as flat constructors?
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All generic node constructors available via lib.libs.campaign
- [ ] #2 tt_fantasy_demo_story campaigns.lua drops its local constructor block
- [ ] #3 New mod can build a full campaign using only lib.libs.campaign without depending on tt_fantasy_demo_story
- [ ] #4 Tests cover each node constructor shape
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
