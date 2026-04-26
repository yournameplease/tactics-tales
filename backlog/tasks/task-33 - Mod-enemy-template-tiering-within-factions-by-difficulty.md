---
id: TASK-33
title: 'Mod: enemy template tiering within factions by difficulty'
status: To Do
assignee: []
created_date: '2026-04-26 19:12'
updated_date: '2026-04-26 20:09'
labels: []
milestone: m-7
dependencies: []
priority: medium
ordinal: 2000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. Faction data optionally declares difficulty tiers for slot mappings (e.g. at base_difficulty 0 use "bandit_rookie", at 2+ use "bandit_veteran"). The battle factory reads base_difficulty from config.memory and selects the appropriate tier when resolving faction tags to character templates. Falls back to tier 0 if no matching tier.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Faction data structure supports optional difficulty-tiered template mappings
- [ ] #2 Battle factory reads base_difficulty from config.memory to select tier
- [ ] #3 Falls back to tier 0 if no tier matches
- [ ] #4 Works with existing faction tag resolution in the battle factory
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
