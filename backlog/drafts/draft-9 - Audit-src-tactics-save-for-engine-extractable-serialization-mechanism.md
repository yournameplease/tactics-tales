---
id: DRAFT-9
title: Audit src/tactics/save for engine-extractable serialization mechanism
status: Draft
assignee: []
created_date: '2026-05-22 23:52'
labels: []
milestone: m-24
dependencies:
  - TASK-158
ordinal: 6000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After the m-24 relocation lands and the engine seam is proven in place, audit `src/tactics/save/` to separate **mechanism** (serializer, slot manager, file I/O, save format versioning) from **schema** (roster, campaign state, character data — all game-domain).

The mechanism layer is potentially extractable into Crane; the schema layer is tactics-specific and stays in the game.

This task is the *audit + recommendation*, not the extraction. Produce:

1. A file-by-file breakdown of what's mechanism vs. schema.
2. A list of any domain leaks in the mechanism layer that would need to be decoupled before extraction (analogous to the four decoupling tasks in m-24).
3. A recommendation: is the mechanism layer substantial and clean enough to be worth extracting, or is it too thin / too coupled to justify the seam?

If the recommendation is "extract," follow up with concrete decoupling and relocation tasks. If "leave it," document why so we don't re-audit later.

**Why this is a draft:** the audit's value depends on what we learn from doing the m-24 relocation itself. Save's coupling profile may look different after we've practiced the extraction pattern once.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 File-by-file mechanism vs. schema breakdown is documented
- [ ] #2 Domain leaks in the mechanism layer are listed
- [ ] #3 Recommendation (extract or leave) is stated with rationale
- [ ] #4 If recommendation is 'extract,' follow-up tasks are created for decoupling and relocation
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
