---
id: TASK-77
title: Add skill loading to mod system
status: To Do
assignee: []
created_date: '2026-05-04 22:27'
labels: []
milestone: m-13
dependencies:
  - TASK-73
references:
  - docs/adr/skill-system.md
  - src/tactics/mods/mod_schema.lua
  - src/tactics/mods/mod_loader.lua
  - src/tactics/game_data.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Wire skill definitions into the mod loading pipeline, parallel to how items are loaded.

Files to modify:
- `src/tactics/game_data.lua` — add `skills: table<string, SkillDefinition>` field to `GameData`
- `src/tactics/mods/mod_schema.lua` — add `skills` to `mod_content_spec` (optional string path); add `skills_spec` dictionary schema validating each entry against SkillDefinition shape; add `skills` to `game_data_schema`
- `src/tactics/mods/mod_loader.lua` — add `load_mod_map` call for skills (same pattern as items)
- Each mod's `mod.lua` may declare `skills = "game_data/skills"` in `content`

Validation rules:
- `effect_type` must be `"heal"` or `"damage"`
- `heal_amount` required when `effect_type = "heal"`
- `damage` and `accuracy` required when `effect_type = "damage"`
- `targeting` required
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 A mod with game_data/skills.lua loads without error and game_data.skills is populated
- [ ] #2 A skill referencing an unknown effect_type fails schema validation
- [ ] #3 Missing required effect fields (heal_amount, damage) fail validation
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
