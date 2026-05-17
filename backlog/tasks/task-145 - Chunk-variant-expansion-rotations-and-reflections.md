---
id: TASK-145
title: Chunk variant expansion (rotations and reflections)
status: Done
assignee: []
created_date: '2026-05-17 01:27'
updated_date: '2026-05-17 01:38'
labels: []
milestone: m-21
dependencies: []
references:
  - docs/specs/procgen-map-spec.md
  - src/tactics/battle/map/procgen/chunk_parser.lua
ordinal: 3500
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Per spec §4.6: expand a parsed chunk into the set of variants permitted by its transformation tags (`rotate_90`, `rotate_180`, `flip_h`, `flip_v`). Variants are first-class chunk records with their own derived name (`<base>|rot90|flip_h`), transformed glyph rows, swapped dimensions where rotation applies, and remapped exit zones per face. Tags compose to form a transformation group (`rotate_90 flip_h` → up to 8 variants); tile-identical variants are deduplicated.

Module: `src/tactics/battle/map/procgen/chunk_variants.lua` (or similar). Exposes a function that takes a list of base ChunkRecord and returns a flat list including all permitted variants. Chunk selection (TASK-138) consumes the expanded list, so dimension matching needs no special-casing for rotation — a `rotate_90`-tagged W×H chunk simply appears as both a W×H and an H×W variant in the pool.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A chunk with no transformation tags expands to a single variant (itself).
- [ ] #2 `rotate_90` produces up to 4 rotational variants; non-square chunks see their dimensions swap on 90°/270° rotations.
- [ ] #3 `flip_h`/`flip_v` produce reflected variants; combined with rotation tags, the full dihedral group is produced.
- [ ] #4 Exit zones are correctly remapped under every transformation (north↔east↔south↔west cycles for rotation; range-reverse on reflections).
- [ ] #5 Spawn glyphs and `d` markers are repositioned consistently with the transformation.
- [ ] #6 Tile-identical variants are deduplicated (e.g. a 4-fold symmetric chunk tagged `rotate_90` yields one variant).
- [ ] #7 Variant names follow `<base>|<op1>|<op2>` convention.
- [ ] #8 Spec coverage in src/spec/battle/map/procgen/chunk_variants_spec.lua.
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
