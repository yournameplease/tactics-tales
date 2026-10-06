---
id: TASK-78
title: Add skill_loadout to character templates
status: Done
assignee: []
created_date: '2026-05-04 22:27'
updated_date: '2026-05-04 23:01'
labels: []
milestone: m-13
dependencies:
  - TASK-73
references:
  - docs/adr/skill-system.md
  - src/tactics/character/character_generator.lua
  - src/tactics/character/definition.lua
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add `skill_loadout` to the character template system so mod authors can assign skills to characters.

Files to modify:
- `src/tactics/mods/mod_schema.lua` — add `skill_loadout = s.optional(s.list(s.reference("skills")))` to `character_template_spec`
- `src/tactics/character/definition.lua` — add `skill_loadout?: string[]` to `CharacterTemplate` type and `Character` type
- `src/tactics/character/character_generator.lua` — add `skill_loadout` to `apply_template_to_parent` (replace semantics: `child.skill_loadout or parent.skill_loadout`, same as `item_loadout`); copy to generated Character

Inheritance: replace (not merge) — consistent with `item_loadout`.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Character template with skill_loadout generates a Character carrying that skill list
- [ ] #2 Referencing an undefined skill ID in skill_loadout fails schema validation
- [ ] #3 Child template with skill_loadout replaces parent's skill_loadout entirely
- [ ] #4 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
