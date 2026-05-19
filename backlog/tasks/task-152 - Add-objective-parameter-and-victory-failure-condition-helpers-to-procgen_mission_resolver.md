---
id: TASK-152
title: >-
  Add objective parameter and victory/failure condition helpers to
  procgen_mission_resolver
status: To Do
assignee: []
created_date: '2026-05-19 22:50'
updated_date: '2026-05-19 22:50'
labels: []
milestone: m-23
dependencies:
  - TASK-151
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Modify `mods/tt_procedural_campaign/lib/procgen_mission_resolver.lua` to support `kill_boss` and `rout` objectives.

**`build_procgen_mission`** gains an `objective` string parameter (default `"rout"`). Forward it into the map `definition` table so `chunk_selector` places a boss_room chunk when objective is `"kill_boss"`.

**Two new local helpers:**

`victory_conditions_for(objective, battle_map)`:
- `"rout"` → `{ battle.victory.rout() }`
- `"kill_boss"` → `{ battle_objectives.defeat_tagged("Defeat the boss", "boss") }` — use the `defeat_tagged` factory from `src/tactics/battle/objective.lua` (already used in the codebase via `battle_lib`)

`failure_conditions_for(objective)`:
- Both `"rout"` and `"kill_boss"` → `{ battle.failure.tagged_unit_dies("hero") }` (same as current hardcoded value)

Replace the hardcoded `victory_conditions` and `failure_conditions` in the returned mission definition with calls to these helpers.

**References:**
- `src/tactics/battle/objective.lua` — `defeat_tagged(text, tag)` factory
- `mods/base/lib/battle.lua` — `battle.victory.rout()`, `battle.failure.tagged_unit_dies(tag)`

Depends on TASK-151 (label-driven build_units, so boss-tagged units are correctly spawned).
<!-- SECTION:DESCRIPTION:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
