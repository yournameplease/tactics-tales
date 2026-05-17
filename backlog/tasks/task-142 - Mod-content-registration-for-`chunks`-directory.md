---
id: TASK-142
title: Mod content registration for `chunks` directory
status: To Do
assignee: []
created_date: '2026-05-17 00:41'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
  - mods/tt_procedural_campaign/mod.lua
ordinal: 8000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per spec §7.1: extend the mod loader to recognize a `chunks` entry in `mod.lua` `content`, scan the directory for `*.chunks` files, and merge them into a global theme registry keyed by filename stem. Multiple mods may contribute to the same theme; chunk names merge by name (later mods override earlier; emit warning on collision).
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A mod can declare `content.chunks = "game_data/chunks"` and have its files loaded at mod-load time.
- [ ] #2 Theme registry exposes `get_theme(name) → {chunks=[...]}` for procgen consumption.
- [ ] #3 Chunk-name collisions across mods emit a log warning and the later mod wins.
- [ ] #4 Existing mods (base, tt_procedural_campaign) without a `chunks` entry continue to load.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
