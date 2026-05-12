# Pod Generation Spec

## Concepts

**Spawn Group** — A named set of spawn points on a map, authored in Tiled. Each group has a role, a facing, and optionally a threat multiplier. The engine fills it with units at mission start (or on a trigger, for reinforcements).

**Pod** — The set of units spawned into a Spawn Group for a given mission run. Composition is determined by the mission's faction template, the group's role, and any constraints.

**Faction Template** — Mod-defined data describing a faction's unit pool, upgrade options, and formation preference. Shared across all missions that use that faction.

---

## Spawn Group Properties

| Property | Required | Default | Description |
|---|---|---|---|
| `role` | yes | — | Tactical intent: `patrol`, `guard`, `ambush`, `reinforce` |
| `facing` | yes | — | Cardinal direction the pod faces (north/south/east/west) |
| `threat_mult` | no | `1.0` | Scales this pod's budget relative to `base_pod_budget` |
| `required_tags` | no | — | At least one unit must match each tag |
| `forbidden_tags` | no | — | No unit may match any of these tags |
| `from` | reinforce only | — | Entry edge for reinforcement waves |
| `trigger` | reinforce only | — | Spawn trigger (see Reinforcements) |

---

## Roles

Roles define soft tag preferences used when selecting units from the faction pool. They are engine-defined but reference faction-defined tags.

| Role | Prefers | Avoids | Notes |
|---|---|---|---|
| `patrol` | `mobile`, `grunt` | — | Standard roaming enemies along the critical path |
| `guard` | `armored`, `leader` | `flier` | Stationary, blocks a chokepoint or objective |
| `ambush` | `ranged`, `high_damage` | `armored`, `slow` | Off the critical path; also used for reinforcement flavor |
| `reinforce` | varies by trigger type | — | Empty at battle start; spawns on trigger |

Spawn Group constraints (`required_tags`, `forbidden_tags`) override role preferences where they conflict.

---

## Budget

Each Spawn Group receives a budget of:

```
pod_budget = base_pod_budget × threat_mult
```

`base_pod_budget` is set on the Mission definition. It represents the cost a 1.0× pod may spend on units and upgrades combined.

The generator fills unit slots first, then spends any remaining budget on upgrades. Pods are independent — adjusting one pod's `threat_mult` does not affect others.

**Reinforcements** draw from a separate `reinforce_budget` on the Mission definition, so waves do not compete with starting pods.

---

## Unit Tags

Tags are intrinsic properties on enemy Character definitions in mod data. Examples: `grunt`, `ranged`, `armored`, `mobile`, `slow`, `flier`, `healer`, `high_damage`, `leader`. Factions may define additional tags.

---

## Upgrades

Each faction template defines a list of upgrades available to its units. The generator spends remaining pod budget on upgrades after filling unit slots.

Each upgrade has:
- `cost` — budget cost (fractional)
- `rule` — eligibility condition and effect (e.g. `weapon:dagger → sword`, `+1 hp`, `weapon:1h and not ranged → add shield`)
- Upgrades are applied round-robin across pod members before any unit receives a second upgrade
- Maximum two upgrades per unit
- Upgrade options are faction-specific and should produce visible changes to the unit sprite

**Threat progression across a run:** low `threat_mult` early → base templates only. Higher multipliers later → same faction with visible weapon and equipment upgrades, without invisible stat inflation.

---

## Formations

Formation style is defined on the faction template, not per-map. Facing comes from the Spawn Group.

| Formation | Description | Example factions |
|---|---|---|
| `scattered` | Random positions within the rectangle | Bandits, rabble |
| `ranked` | Fills from facing edge inward; leader centered in back row | Militia, soldiers |
| `clustered` | Units pack toward rectangle center; leader in middle | Cultists, defensive groups |

For odd-count pods, front rows are centered and back rows fill symmetrically. The leader template always occupies the designated anchor position (back-center for ranked, center for clustered).

Mixed-unit pods (planned): role tag preferences apply per-row within a formation rather than per-pod as a whole.

---

## Reinforcements

Reinforcement Spawn Groups are empty at battle start and spawn on a trigger. They share all standard Spawn Group properties plus:

**Triggers:**
- `turn:N` — spawns at the start of turn N
- `kill:unit_id` — spawns when a specific unit dies
- `kill_count:N` — spawns when N enemies total have been killed
- Triggers may be combined; reinforcements can be `one_shot` or recurring

**Design classes:**

| Class | `threat_mult` | `role` | `from` | Notes |
|---|---|---|---|---|
| Anti-turtle | high (1.5–2.0) | `ambush` | Behind player | Intended to punish stalling; meant to be fled, not fought |
| Distraction | low (0.5–0.8) | `patrol` or `ambush` | Critical path | Recurring pacing texture; fodder-level threat |

**Telegraphing:** A Battle Script dialogue line should fire one turn before any reinforcement wave. Ambush spawns that act on the turn they appear are prohibited — reinforcements always wait until the following phase to act.

**Boss-linked reinforcements:** Reinforcement triggers support a `stop_on_kill:unit_id` condition to halt recurring waves when a boss is defeated.

---

## Authoring Summary

Typical Spawn Group authoring cost:
1. Place rectangle in Tiled
2. Set `role` and `facing`
3. Optionally set `threat_mult` if this pod should be notably easier or harder than baseline

Constraints (`required_tags`, `forbidden_tags`) are only needed when map geometry demands it. Formation and upgrade behavior come from the faction template and require no per-map authoring.

Post-playtest tuning: adjust `threat_mult` on specific groups or `base_pod_budget` on the Mission definition. No map editing required.
