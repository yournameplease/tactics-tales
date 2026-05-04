---
id: DRAFT-8
title: >-
  Typed Campaign State accessors — replace raw string store with structured
  getters/setters
status: Draft
assignee: []
created_date: '2026-05-03 19:24'
labels: []
milestone: m-12
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Campaign State stores all values as strings (`.text` field). The procedural mod is littered with `tonumber(sc.memory:get("key").text or "0")` and nil-guards because numeric and boolean values have no native representation. The interface is maximally shallow — callers must know the string-serialization convention.

Add typed accessors: `sc.memory:set_number(key, n)` / `sc.memory:get_number(key, default)`, and equivalents for boolean and string. The raw `.text` store remains the implementation.

**Needs design discussion before implementation**: Should typed entries be stored differently (separate fields, or encoded in `.text`)? How do nil/missing keys behave per type? Does this affect save-game serialization? Are there other Campaign State consumers in src/ that need updating?
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 sc.memory:set_number / get_number round-trips correctly
- [ ] #2 sc.memory:set_boolean / get_boolean round-trips correctly
- [ ] #3 Procedural mod removes manual tonumber() and nil-guard boilerplate
- [ ] #4 Save/load still works
- [ ] #5 LuaCATS types updated
- [ ] #6 Tests cover typed round-trips
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
