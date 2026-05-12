# Faction Skills Design Spec

## Overview

Skills are learnable active or passive abilities attached to Characters and tracked on their battlefield Unit instance. This document covers the three core enemy factions — Cultists, Bandits, and Militia — including skill rosters, visual telegraphing, and design intent.

Skills are rare early game (commanders only), appear on pod-leaders by mid game, and should never exceed roughly half the enemy units on a typical map even at endgame. This scarcity keeps skills feeling dangerous and meaningful rather than routine.

---

## Visual Telegraphing

### The Problem

Skill-holders must be identifiable before the player engages them. The standard status outline is hard to read at small sizes, particles are too noisy on a busy map, and the faction color palette is already fixed.

### Primary Signal: Sprite Accent Color

A consistent **yellow accent** applied to one faction-specific body part marks any unit with at least one skill. This creates a cross-faction visual language — players learn it once and it applies everywhere.

| Faction | Accent Location | Rationale |
|---------|----------------|-----------|
| Cultists | Glowing eyes (or charm) | Eyes are a natural focal point on the large head; yellow eyes read as supernatural without feeling like UI |
| Bandits | Animal mask or bare torso marking | Masks already signal stronger variants; yellow highlights the distinguishing feature |
| Militia | Sash or belt stripe | Single horizontal stripe across the torso; historically accurate commander marking; easy to sprite |

The yellow accent should be tested against common tile palettes early — it reads differently on bright sandy maps vs. dark dungeon floors.

### Secondary Signal: UI Glyph

A small star or glyph placed underfoot, confirms skill-holder status on hover. This serves as a catch-all for cases where sprite differentiation alone is ambiguous (e.g., a standard militia guard with Hold the Line).

---

## Faction Identities

### Cultists
Blood magic is the core identity. HP is a resource — cultists spend it to power rituals and spells. This makes them dangerous when left alone to accumulate actions, and creates a tension between killing them quickly vs. managing other threats.

Shamans are a subtype: weaker melee but with healing and summoning access. Skeletons are expendable units created by Raise Soldier; they have no skills of their own.

### Bandits
Controlled aggression and intimidation. Strong openers but vulnerable if the player survives the first wave. Skills reward clustering and punish passive play. Shamans are a secondary subtype with primal totem-based magic, distinct from cultist ritualism.

### Militia
The establishment faction. Professional soldiers with formation-based coordination, spears, armor, and elemental mages. Skills feel institutional — things from a medieval army manual — rather than scrappy or magical. Their "cost" mechanic is coordination sacrifice: spending a unit's movement, counterattack window, or an ally's action.

---

## Skill Reference

### Cultists

| Skill | Type | Range | Cooldown | Description | Notes |
|-------|------|-------|----------|-------------|-------|
| Share Life | Active | 1 | — | Divide current HP evenly between self and target ally | Distinctive; rewards pairing damaged units |
| Sacrifice | Active | 1 | — | This unit dies; fully heal target ally | |
| Soul Strike | Active | 2 | — | Deal 3 damage ignoring armor; costs 1 HP | |
| Blood Pact | Active | — | — | Take 1 damage; next attacker to kill you also dies. Expires after 1 turn | Could be a passive on a "martyr" cultist subtype |
| Raise Soldier | Active | 1 | — | Spawn a skeleton unit; costs 1 HP | Spawned skeleton acts next turn, not the turn it spawns |
| Blood Siphon | Active | 1 | - | Deal 1 damage. On kill, gain +1 max HP for this battle | Rewards aggression; creates a momentum threat |
| Wither | Active | 1–2 | 2 turns | Reduce target's damage by 1 for 2 turns | Fills the debuff space; especially oppressive on strong player units |

### Bandits

| Skill | Type | Range | Cooldown | Description | Notes |
|-------|------|-------|----------|-------------|-------|
| War Cry | Active | — | Once per battle | Next turn this unit gains a double-attack | Classic opener; works as a bandit chief signature |
| Ritual Healing | Active | — | — | Heal 3 HP | Shaman-only; straightforward but functional |
| Intimidate | Active | 1–2 | 3 turns | Target cannot move next turn | Strong debuff; consider adding a visual status indicator |
| Mark Prey | Active | 1–2 | 3 turns | Target takes +1 damage from all hits next turn | Renamed from *Call Target*; fits predatory bandit flavor |
| Rampage | Active | — | Once per battle | Attack all adjacent enemies; no counterattack. Lose next turn | "Lose next turn" creates a player window to punish |
| Blood Ritual | Active | Infinite | — | Deal 1 HP damage to each adjacent bandit ally; heal target ally for that total. Shaman only | Scales with pack size; distinct from cultist HP costs — primal vs. ritualistic |

### Militia

| Skill | Type | Range | Cooldown | Description | Notes |
|-------|------|-------|----------|-------------|-------|
| Heal | Active | 1 | 3 | Heal target ally 4 HP. Cleric only | Standard; necessary anchor for the faction |
| Field Healing | Active | 1 | 3 | Heal all adjacent allies 1 HP. Cleric only | No targeting required; works mid-melee |
| Mass Heal | Active | 1–2 | Once per battle | Heal all units in range 2 HP. Cleric only | Requires cleric to not have moved that turn |
| Rally | Active | 1 | 2 | Give target ally an extra action this turn | Commander signature; very powerful — once per battle is correct |
| Hold the Line | Active | 1 | 3 turns | Adjacent allies gain +1 defense until start of next turn | Formation anchor; pairs well with spear grunts |
| Advance Formation | Active | 1 | — | All adjacent allies may move 1 extra tile this turn. Commander only | Institutional feel; rewards tight formations |

