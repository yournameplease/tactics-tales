---
id: TASK-25
title: 'Mod: define faction data structure'
status: Done
assignee: []
created_date: '2026-04-26 19:11'
updated_date: '2026-04-27 02:25'
labels: []
milestone: m-5
dependencies: []
priority: high
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Factions are declared in `mods/tt_procedural_story/game_data/factions.lua` as a `table<string, FactionDefinition>`. Each faction maps spawn slot tags to character template IDs via a `tiers` array (one table per difficulty tier), plus a `fallbacks` table for missing slots.

Four spawn slot tags: `enemy_infantry`, `enemy_commander`, `enemy_tank`, `enemy_ranged`.

Faction shape:
```
{
  name = string,
  tiers = {
    { enemy_infantry="id", enemy_commander="id", enemy_tank="id", enemy_ranged?="id" },
    ...
  },
  fallbacks = { enemy_ranged = "enemy_infantry" },
}
```

Three factions to define:
- **bandits**: tier1 infantry=bandit_goon/commander=bandit_boss/tank=bandit_guard; tier2 infantry=bandit_axe/commander=bandit_berzerker/tank=bandit_guard; no ranged
- **cultists**: tier1 infantry=cultist_goon/commander=cultist_boss/tank=cultist_guard; tier2 infantry=cultist_spearman/commander=cultist_boss/tank=cultist_guard; no ranged
- **militia**: tier1 infantry=militia_spearman/commander=militia_spear_captain/tank=militia_armor/ranged=militia_archer; tier2 infantry=militia_sword/commander=militia_sword_captain/tank=militia_armor/ranged=militia_archer

LuaCATS types `FactionSlotTag`, `FactionTier`, `FactionDefinition`, and `ModFactionsModule` go in `mods/types.d.lua`. File is loaded via `include()`, no mod.lua registration needed.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 FactionDefinition, FactionTier, FactionSlotTag, and ModFactionsModule types added to mods/types.d.lua
- [x] #2 mods/tt_procedural_story/game_data/factions.lua created returning a ModFactionsModule with bandits, cultists, and militia entries
- [x] #3 All three factions have exactly 2 tiers with correct template assignments
- [x] #4 All three factions declare fallbacks = { enemy_ranged = 'enemy_infantry' }
- [x] #5 make test passes
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 All acceptance criteria met
- [ ] #2 make test passes
<!-- DOD:END -->
