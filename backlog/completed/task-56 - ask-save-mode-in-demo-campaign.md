---
id: TASK-56
title: '"ask" save mode in demo campaign'
status: Done
assignee: []
created_date: '2026-05-01 14:30'
updated_date: '2026-05-01 14:47'
labels:
  - needs-triage
dependencies:
  - TASK-53
  - TASK-54
  - TASK-55
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Wire up the "ask" saving config option in the demo campaign now that detour, memory_branch, and stats substitution are available. This re-enables the previously commented-out option and updates all victory nodes to use shared save sub-nodes.

**What to build** in `mods/tt_fantasy_demo_story/game_data/campaigns.lua`:

1. **Re-enable "ask" saving option** in GENERIC_CONFIG (currently commented out with a TODO). Add description: e.g. "After each victory, choose whether to save."

2. **Update Easy preset** to `saving = "ask"` (was `"ironman"`).

3. **Add shared save sub-nodes** to `demo_story.nodes`:
   ```
   save_auto = {
     campaigns.save_game(),
     campaigns.story_text("Progress saved."),
   }
   save_ask = {
     campaigns.select_option({
       { id = "save",  name = "Save",  description = "Save your progress." },
       { id = "skip",  name = "Skip",  description = "Continue without saving." },
     }, "save_choice"),
     lib.libs.story.memory_branch(
       function(c, s) return s["save_choice"] == "save" end,
       campaigns.detour("save_auto"),
       campaigns.advance()
     ),
   }
   ```

4. **Update all 5 victory nodes** (ch_1_v through ch_5_v). Replace inline `save_game()` / `story_text("Progress saved.")` with:
   - A death count blurb (when `deaths == "classic"`):
     `lib.libs.story.config_branch(function(c) return c.deaths == "classic" end, campaigns.story_text("${stats.current.units_lost} of your units fell in combat."), campaigns.advance())`
   - A save detour:
     `lib.libs.story.config_branch(function(c) return c.saving == "ask" end, campaigns.detour("save_ask"), campaigns.detour("save_auto"))`

**Depends on:**
- TASK-53: factory state arg + memory_branch (provides `memory_branch`)
- TASK-54: detour node type (provides `campaigns.detour`)
- TASK-55: stats text substitution (provides `${stats.current.units_lost}`)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 'ask' saving option is present and enabled in GENERIC_CONFIG with a description
- [ ] #2 Easy preset uses saving = 'ask'
- [ ] #3 save_auto and save_ask nodes exist in demo_story.nodes
- [ ] #4 In 'ask' mode, victory shows a Save/Skip prompt; choosing Save triggers save_game, choosing Skip does not
- [ ] #5 In 'ironman' and 'hardcore' modes, victory saves automatically without prompting
- [ ] #6 When deaths == 'classic', victory text includes '${stats.current.units_lost} of your units fell in combat.'
- [ ] #7 When deaths == 'casual', the death count line does not appear
- [ ] #8 All 5 chapter victory nodes use the shared save detour pattern (no inline save_game calls)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
