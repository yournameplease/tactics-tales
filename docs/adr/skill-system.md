# Skill System Spec

_Session date: 2026-05-04_

## Pre-decided (not re-litigated)

- Skills defined entirely in mod data — no hardcoded skills in the engine.
- Skills list lives on the Character (persistent across battles); cooldown and uses-remaining state live on the Unit (battle-instance only).
- Two resource constraints: turn-based cooldown and per-battle use limit — both optional, independently configurable.
- HP cost allowed; self-kill from HP cost is allowed, and the skill effect still fires after the caster dies.
- Two effect types for this release: **heal** (targets one unit, no Combat exchange) and **damage** (true damage, no counterattack, can miss per skill accuracy).

---

## Mod data schema

### File location

Each mod places skill definitions in `game_data/skills.lua`, parallel to `items.lua`:

```
mods/<mod-name>/
  game_data/
    items.lua
    skills.lua   ← skill definitions
    characters.lua
```

### Skill definition shape

```lua
-- game_data/skills.lua
return {
  heal = {
    name            = "Heal",
    effect_type     = "heal",
    heal_amount     = 3,          -- flat HP restored
    hp_cost         = 1,          -- HP deducted on use; nil = no cost
    cooldown        = 2,          -- turns unavailable after use; nil = no cooldown
    uses_per_battle = nil,        -- max uses per battle; nil = unlimited
    targeting       = {
      range_min = 1,
      range_max = 1,
      get_selection_tiles    = function(origin, map) ... end,
      get_targets_for_selection = function(origin, selection, map) ... end,
      is_target_valid        = function(origin, selection, map) ... end,
    },
  },

  fireball = {
    name            = "Fireball",
    effect_type     = "damage",
    damage          = 5,          -- flat true damage (no defense reduction)
    accuracy        = 80,         -- hit chance 0–100; can miss
    hp_cost         = nil,
    cooldown        = nil,
    uses_per_battle = 1,
    targeting       = { ... },
  },
}
```

**`effect_type` values (this release):**

| `effect_type` | Effect-specific fields | Notes |
|---|---|---|
| `"heal"` | `heal_amount` | Flat HP restored. No Combat exchange. |
| `"damage"` | `damage`, `accuracy` | True damage (ignores defense). No counterattack. Uses skill `accuracy` for hit chance. |

### Targeting

Skill `targeting` reuses the same schema as weapon targeting:

- `range_min`, `range_max` — tile range constraints
- `get_selection_tiles(origin, map)` — returns candidate tiles
- `get_targets_for_selection(origin, selection, map)` — returns units at the selected tile
- `is_target_valid(origin, selection, map)` — true if the selection is legal

Self-targeting is not engine-enforced — include or exclude the caster's tile in `is_target_valid` as appropriate.

**Heal targeting convention:** exclude full-HP allies and include only allies (`side == "player"`) via `is_target_valid`. The engine does not enforce this — it is authored in the mod's targeting function.

### Resource semantics

- `cooldown = nil` — no cooldown constraint.
- `uses_per_battle = nil` — no per-battle cap (unlimited uses, only cooldown applies).
- A skill may have both, one, or neither constraint.

---

## Character assignment

### `skill_loadout` on templates

```lua
protagonist = {
  parent_template = "human_base",
  hp_max          = 5,
  item_loadout    = { "sword" },
  skill_loadout   = { "heal" },
}
```

- `skill_loadout` is a list of skill IDs defined in any loaded mod's `skills.lua`.
- Inheritance follows `parent_template` with **replace** semantics — same as `item_loadout`. If a child template specifies `skill_loadout`, it fully replaces the parent's list.

---

## Battle action menu

### Turn menu entry

The **Skills** entry is hidden when the unit has no skills. When visible, it opens a sub-menu.

```
TURN MENU (unit has skills)    TURN MENU (unit has no skills)
├ Attack                       ├ Attack
├ Skills → sub-menu            └ Wait
└ Wait
```

### Skills sub-menu

All of the unit's skills are listed. Unavailable skills are greyed with a short reason; available skills are selectable.

```
SKILLS
► Heal         HP:1
  Fireball  [--]  CD:2
  War Cry   [--]  no valid targets
```

Unavailability reasons (displayed inline):

| Condition | Label |
|---|---|
| Cooldown active | `CD: N` (turns remaining) |
| Uses exhausted | `0/N` |
| No valid targets | `no valid targets` |
| Can't afford HP cost | `HP:N` (when hp_current < hp_cost) |

**Valid target computation** is done after the unit has moved (from the destination tile), consistent with how attack range is evaluated.

---

## Skill execution flow

```
1. Player selects skill from sub-menu
2. Targeting phase: player selects a target tile
   (invalid tiles and full-HP allies for heal are excluded)
3. Player confirms
4. HP cost deducted from caster (may reduce HP to 0, killing the caster)
5. Skill effect fires (even if caster is now dead)
6. Caster death is processed normally (permadeath)
```

Using a Skill **consumes the unit's action** — same as attacking. The turn menu choice is `[Attack | Skill | Wait]`, pick one.

**Cooldown state** is tracked on the Unit as `cooldown_remaining` per skill. It decrements by 1 at the **start of the caster's next turn**. A cooldown of 2 means the skill is unavailable for the caster's next 2 turns.

**Animation:** no custom animation hooks in this release. Existing battle feedback (HP flash, unit death) applies automatically.

---

## Enemy AI

Enemy units can use skills. Skill priority (whether the AI prefers skills over attacking, or uses them as fallback) is defined in the **`UnitAI` definition**, alongside `move` and `target_sides`. No `UnitAI` fields are specified here — that is the AI sub-system's concern.

---

## Out of scope for this release

- Granting skills to Characters via story nodes (`grant_skill`).
- Animation callbacks per skill.
- Enemy AI skill priority field definition (deferred to AI sub-system spec).
- Skills with `consumes_action = false` (free actions / buffs).
- Passive skills.
