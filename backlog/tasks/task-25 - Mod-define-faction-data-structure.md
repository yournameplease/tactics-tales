---
id: TASK-25
title: 'Mod: define faction data structure'
status: To Do
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-26 20:08'
labels: []
milestone: m-5
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Factions are declared in the content mod as named tables mapping spawn slot tags (e.g. "enemy_infantry", "enemy_commander") to character template IDs. Each faction carries display metadata and optional difficulty tiers for later use. This is a mod-level data convention; the engine does not need a faction concept. Mod schema validation of faction structure is a minor engine touch only if the faction data is loaded via mod_loader.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Faction table shape is defined with tag-to-template mappings
- [ ] #2 Factions are declared in the content mod
- [ ] #3 Optional difficulty tiers are supported in the data shape
- [ ] #4 A worked example faction exists in test data
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
