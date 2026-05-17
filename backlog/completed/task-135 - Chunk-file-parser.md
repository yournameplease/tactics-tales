---
id: TASK-135
title: Chunk file parser
status: Done
assignee: []
created_date: '2026-05-17 00:40'
updated_date: '2026-05-17 00:59'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Parse `.chunks` text files into in-memory chunk records per spec §7. Validate corners, border characters, interior vocabulary (`# . i r t c d p a`), directional marker face placement, single contiguous exit run per face (hard-reject split exits), `d`↔`deployment` tag consistency, unique names, and minimum cell dim ≥ 3. Read raw file content via `fetch()`; expose `parse(text) → chunks` and a higher-level `load_theme(path) → theme_chunks`. No engine wiring in this task.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Parses the example chunk file from spec §7.3 into structured chunk records with tags, dimensions, glyph grid, derived exit zones per face.
- [x] #2 Rejects each malformed input in spec §10 (corner, border char, interior char, mismatched directional, split exits, dup name, d/deployment mismatch) with a useful error message.
- [x] #3 Unknown tags emit a log warning but do not fail parsing.
- [x] #4 Spec coverage in src/spec/battle/map/procgen/chunk_parser_spec.lua.
<!-- AC:END -->

## Final Summary

<!-- SECTION:FINAL_SUMMARY:BEGIN -->
Implemented `src/tactics/battle/map/procgen/chunk_parser.lua` with two entry points: `parse(text) → ChunkRecord[]` (per spec §7.2) and `load_theme(path)` (fetch-backed wrapper). Each record carries `name`, `width`, `height`, `rows`, `tags`, and a derived `exits` table with `north`/`south`/`east`/`west` exit zones (`{min, max}` 1-indexed inclusive, or nil).

Validation covers the full spec §10 list: corner ≠ '#', invalid border/interior chars, directional markers on the wrong face, split exits (hard-rejected per design decision), duplicate chunk names, `d`↔`deployment` tag consistency, declared row width mismatch, and minimum interior dimension ≥ 3×3. Unknown tags emit `log.warn` rather than failing parsing (forward-compatible with planned `boss`/`no_enemy` tags).

Spec coverage at `src/spec/battle/map/procgen/chunk_parser_spec.lua` — 20 tests including the spec §7.3 example end-to-end. Full suite (1121 tests) passes.

Also fixed dimension/row-width mismatches in the spec doc's §7.3 example (the original example chunks had inconsistent widths).
<!-- SECTION:FINAL_SUMMARY:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [x] #1 All acceptance criteria met
- [x] #2 make test passes
<!-- DOD:END -->
