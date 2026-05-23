---
id: DRAFT-10
title: Cut Crane subrepo and document public surface convention
status: Draft
assignee: []
created_date: '2026-05-23 00:11'
labels: []
milestone: m-24
dependencies:
  - TASK-158
ordinal: 7000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After TASK-158 lands and the `crane/` directory is proven in place, cut it into its own git repository and wire it back into the tactics game as a submodule.

**Steps:**

1. Initialize a new git repo for Crane (preserve history via `git subtree split` if worth it; otherwise a fresh init is acceptable for a single-consumer engine at this stage).
2. Remove the in-tree `crane/` directory from the tactics game and re-add it as a git submodule pointing at the new repo.
3. Verify `make test` and runtime behavior are unchanged.
4. Author `crane/CONTEXT.md` documenting the engine's purpose, Picotron-only constraint, and **public surface convention** (see below).
5. Tag an initial version (v0.1.0 or similar — versioning is "semver-ish, when I remember," per discussion).

**Public surface convention to document in crane/CONTEXT.md:**

- Stable, supported modules are listed explicitly in a "Public API" section.
- Anything under `crane/_internal/` is fair game to refactor without notice. Consumers should not require modules from `_internal/`.
- No code-level enforcement (no `init.lua` re-export facade for now) — the convention is documentation-only plus directory naming.
- If consumers later need single-import ergonomics or stronger boundaries, revisit with a `crane/init.lua` facade or LuaCATS-typed entry module.

Move any obviously-internal helpers into `crane/_internal/` as part of this task; everything else stays at its current path and is implicitly public.

**Versioning notes to capture:**

- Semver loose ("when I remember to tag")
- Breaking changes warrant a new major/minor tag and a brief note in the repo's CHANGELOG or commit message
- Consumers pin via submodule SHA; bumping is a deliberate PR in the consumer

**Out of scope:** designing a `crane/init.lua` facade, building CI for Crane, publishing anywhere beyond the local/private remote.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 crane/ is its own git repository
- [ ] #2 tactics game references crane via git submodule with a pinned SHA
- [ ] #3 make test passes and game runs unchanged
- [ ] #4 crane/CONTEXT.md exists and documents purpose, Picotron-only constraint, public surface convention (doc + _internal/), and versioning policy
- [ ] #5 Obviously-internal helpers are moved under crane/_internal/
- [ ] #6 An initial version tag exists on the crane repo
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
