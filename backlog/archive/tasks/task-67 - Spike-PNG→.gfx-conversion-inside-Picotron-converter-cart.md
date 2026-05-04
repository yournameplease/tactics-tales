---
id: TASK-67
title: 'Spike: PNG→.gfx conversion inside Picotron converter cart'
status: To Do
assignee: []
created_date: '2026-05-04 02:12'
labels: []
milestone: m-9
dependencies:
  - TASK-45
priority: high
ordinal: 2500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Research and implement PNG→.gfx userdata conversion inside `tools/tiled_convert.p64`. This is split from TASK-46 because it's an open question whether Picotron can read PNG files natively from the filesystem inside a cart.

**Open question:**
Can `fetch()` or a similar Picotron API load a PNG from the filesystem inside a running cart? Or must the PNG be embedded as a Picotron resource before the converter can access it?

**Spike goals:**
1. Determine the correct Picotron API for reading a PNG file from disk
2. Determine how to write a `.gfx` userdata to disk
3. Implement PNG→.gfx conversion in the converter cart

**Expected output location:**
`game_data/gfx/<tileset_name>.gfx`

**Reference:**
- Tileset PNG: `mods/tt_procedural_campaign/game_data/gfx/tiny_tileset.png`
- The converter (TASK-46) leaves .gfx conversion as a manual step until this spike is resolved
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Picotron API for reading PNG from filesystem is identified and documented
- [ ] #2 Converter cart can read tiny_tileset.png and write a valid .gfx userdata
- [ ] #3 Output .gfx renders correctly when used as the tileset for abandoned_fortress in-engine
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
