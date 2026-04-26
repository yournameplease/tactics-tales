---
id: TASK-32
title: 'Mod: base_difficulty story memory convention and beat increment'
status: To Do
assignee: []
created_date: '2026-04-26 19:12'
updated_date: '2026-04-26 20:09'
labels: []
milestone: m-7
dependencies: []
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Entirely mod Lua. base_difficulty is a story memory key with a defined integer scale (e.g. 0–4). Beat factory nodes write an incremented value to memory using set_memory (or return a set_memory node). Battle factories and filler factories read config.memory.base_difficulty to adjust behavior. Initial value and increment amount are declared in the archetype data. No engine involvement.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 base_difficulty memory key convention is defined with a documented integer scale
- [ ] #2 Beat factory nodes increment base_difficulty in story memory
- [ ] #3 Battle factories and filler factories read base_difficulty from config.memory
- [ ] #4 Initial value and increment are configurable per archetype
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
