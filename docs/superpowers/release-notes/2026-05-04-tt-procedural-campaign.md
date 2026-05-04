# Release Plan: tt_procedural_campaign initial release

**Date:** 2026-05-04

## Goals

1. **`tt_procedural_campaign` mod** — single "Defeat the Evil King" archetype, ~10 beat+filler slots, map reuse fine. Rally Nations deferred.
2. **Beastfolk faction** — both enemy side (faction system) and player side (turncoat mid-battle + story-node grant). Art and specs from user.
3. **Skill system** — fully mod-configurable engine feature. Design session first → spec doc + tasks. Initial sample skills authored in `tt_procedural_campaign`.

## Canonical terminology settled

- Mod name: `tt_procedural_campaign` (was `tt_fantasy_procedural_story` in older tasks — all references updated)
- **Skill**: learnable active ability; known list on Character, cooldown/uses state on Unit. Defined in mod data.

## Skill system design decisions (pre-session)

- Two resource models: turn-based cooldown AND per-battle use limit (both supported)
- HP cost allowed; self-kill from cost is allowed
- Healing: separate action, targets one adjacent ally, no Combat exchange
- Damaging: initiates Combat exchange, no counterattack, true damage (ignores defense)
- Spec output: `docs/adr/skill-system.md` + implementation task cards

## Backlog coverage

| Goal | Tasks |
|------|-------|
| Scaffold mod | TASK-35 (updated) |
| Defeat the Evil King archetype | TASK-36 (scoped), TASK-38 |
| Filler templates | TASK-37 |
| Sequence generation | TASK-22, TASK-23, TASK-24 |
| Faction system | TASK-26 |
| Difficulty pacing | TASK-32, TASK-33 |
| Beastfolk faction | NEW-B |
| Skill system | NEW-C (design), NEW-D (engine), NEW-E (content) |

## Deferred

- TASK-34: recruitment rate overrides (low priority, no blocker)
- TASK-39: shared asset factoring (premature with one mod in scope)
- Rally Nations archetype (TASK-36 scoped to Defeat the Evil King only)
