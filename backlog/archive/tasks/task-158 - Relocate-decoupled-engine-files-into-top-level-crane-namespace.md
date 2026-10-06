---
id: TASK-158
title: Relocate decoupled engine files into top-level crane/ namespace
status: To Do
assignee: []
created_date: '2026-05-22 23:36'
updated_date: '2026-05-22 23:52'
labels: []
milestone: m-24
dependencies:
  - TASK-154
  - TASK-155
  - TASK-156
  - TASK-157
ordinal: 5000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
After the four decoupling tasks (grid cursor hook, ui_manager registry inversion, ui_context_manager split, UILayoutId generalization) land, move the engine-clean files into a new top-level `crane/` directory and rewrite all requires from `src.tactics.<x>` to `crane.<x>`.

The relocation goes directly to the final destination — no interim `src/tactics/engine/` stop — so the require-rewrite is done once.

**Pre-work check:** confirm Picotron's `require` resolution picks up top-level `crane/` from the project root (the existing top-level `lib/` directory suggests it does, but verify before bulk-moving). If the include path needs adjustment, do that first.

**Files to move (verified clean in the audit, assuming the four decoupling tasks are done):**

- All of `src/tactics/util/` → `crane/util/`
- All of `src/tactics/systems/` (event_bus + listener/writer, mutex, tasks) → `crane/systems/`
- `src/tactics/input/input_context.lua` → `crane/input/input_context.lua`
- `src/tactics/draw/draw_target_manager.lua` → `crane/draw/draw_target_manager.lua`
- `src/tactics/animation/page_flip_animator.lua` → `crane/animation/page_flip_animator.lua`
- All of `src/tactics/menu/` (menu_cursor, menu_context, menu_manager, on_screen_keyboard, types, and cursor/*) → `crane/menu/`
- `src/tactics/ui/box.lua`, `layout.lua`, `theme.lua`, `validator.lua`, `ui_context.lua`, `ui_manager.lua` (post-refactor), `components/menu.lua`, and the engine half of the split context manager → `crane/ui/`
- `src/tactics/colors.lua` → `crane/colors.lua`
- `src/tactics/math_util.lua` → `crane/math_util.lua`

Update all requires across the codebase to the new `crane.<x>` paths. Confirm tests still pass and the game still runs.

**Out of scope:** cutting the Crane subrepo, choosing the submodule mechanism, designing a public API surface. Those happen after this move is verified in place. The expected sharing mechanism is git submodule with tags for breaking changes — relevant only as context for why we want the seam to be clean.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 All listed files live under top-level crane/
- [ ] #2 All require paths across the codebase use the crane.<x> form
- [ ] #3 No file under crane/ requires anything under src.tactics.battle, src.tactics.campaign, src.tactics.game, src.tactics.character, or src.tactics.skills
- [ ] #4 Picotron's require resolution finds crane.* modules at runtime
- [ ] #5 make test passes
- [ ] #6 The game runs and is visually/behaviorally unchanged
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
