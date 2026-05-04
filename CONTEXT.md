# Tactics Tales

A moddable tactics-RPG with a storybook aesthetic. Game content (maps, battles, characters, stories, items) is defined in mods and loaded at runtime. The game presents multiple self-contained campaigns — hence "Tactics Tales."

## Language

**Mod**:
A package of behavior and content loaded at runtime. A mod provides zero or more of each content type (maps, battles, characters, items, campaigns) and may depend on other mods, inheriting their content unless overridden. The base game ships as the "base" mod alongside other bundled mods.
_Avoid_: Plugin, expansion, content pack

**Character**:
A persistent roster entity with stats, appearance, and inventory that survives across battles until killed (permadeath).
_Avoid_: Unit (use Unit for the battlefield instance)

**Unit**:
A Character's battlefield instance — exists only for the duration of one battle, has a position, current HP, and side.
_Avoid_: Character (use Character for the persistent entity), BattleUnit (internal code term)

**Roster**:
The persistent group of player-owned Characters available across battles. Characters join the roster via recruitment and leave it permanently via permadeath.
_Avoid_: Party, team, squad

**Combat**:
A full exchange between two units — an attack from the initiating unit followed by a counterattack from the defender (if eligible). Counterattacks can be prevented by weapon range mismatches (melee vs ranged) or certain weapon effects.

**Attack**:
The initiating strike in a Combat exchange. Subject to accuracy.

**Counterattack**:
The defender's retaliatory strike after an Attack. Not always possible — blocked when weapons are incompatible in range or certain weapon effects apply.

**Chapter** (narrative):
A titled section of a Campaign displayed to the player via a chapter header — has a title and optional number or label (e.g., "Prologue"). A player-facing narrative grouping.

**Battle Index**:
A count of how many battles have occurred in a campaign run, tracked internally for stats. The code calls this `chapter` in battle/turn contexts — do not confuse with the narrative Chapter.
_Avoid_: "chapter" when referring to battle count — use "battle index" in discussion to prevent ambiguity.

**Recruitment**:
Adding a Character to the player Roster — either by converting a battlefield Unit (via battle script) or by granting a Character through a campaign story node. Both mechanisms share the same purpose and should use this term.
_Note_: Currently split between `RecruitUnits` (battle script) and `roster_add` (story node) in code — unification is planned.

**Campaign State**:
A persistent key-value store scoped to a campaign run, used to carry player choices, character names, and mod-defined data across story nodes.
_Avoid_: "story memory" (code term), "memory" alone (appears in older code as `set_memory`, `memory_branch` — these are being renamed to `set_state`, `state_branch`), "save data" (too broad — save data includes the roster and other state)

**Victory Condition**:
A rule that ends a battle in the player's favor (e.g., rout all enemies, survive N turns, escape the map).

**Failure Condition**:
A rule that ends a battle in defeat (e.g., all player units die, a key character dies, turn limit exceeded).
_Avoid_: "objective" as a general term for either — it implies something to achieve, which misrepresents failure conditions.

**AI**:
The behavioral ruleset attached to a Unit defining how it acts on its turn — which units it targets and how it positions relative to its attack range.

**Deployment**:
An optional pre-battle phase where the player arranges their units among predefined deployment positions before the battle begins. Not all Missions include it.

**Spawn Group**:
A named set of spawn-point coordinates in a map's `.spawn.lua` file — e.g. `deployment_defense`, `boss_seize`, `reinforce_west`. A Mission's definition lists which Spawn Groups are active for that mission; the engine loads only those groups. Spawn Groups carry per-point properties (`slot`, `facing`, `ai_hint`) and optional per-group properties (`from` for reinforcement entry direction). Layer-level properties in Tiled set defaults inherited by all points in the group; per-point properties override.
_Avoid_: "label" alone (the code key name), "spawn layer" (conflates the Tiled layer with the runtime concept)

**Spawn File**:
A `.spawn.lua` file produced by the Tiled converter alongside the `.map` file. Contains all Spawn Groups for a map, organized under `labels` (always-available groups) and `variant_sets` (mutually exclusive groups). Loaded by the engine when a Mission uses a `tiled` map definition.
_Avoid_: "spawn data", "meta file" (the `_meta.lua` sidecar is a different artifact)

**Side**:
A unit's team affiliation in battle: `player`, `enemy`, or `neutral`. Determines targeting and AI behavior.
_Avoid_: "ally" as a side name — some UI displays neutral as "ally" but this is a presentation detail, not a domain term.

**Battle Script**:
An event-driven authored behavior attached to a battle — a trigger paired with one or more effects that fire when the trigger condition is met (e.g., spawn reinforcements on turn 3, show dialogue when a unit dies).
_Avoid_: Script alone when the battle context is ambiguous

**Mission**:
The authored setup for a single battle — specifies the map, units to spawn, victory/failure conditions, and battle scripts.
_Avoid_: Scenario (too broad; risks collision with future non-battle scenes), BattleDefinition (code term)

**Campaign**:
A self-contained playable story with narrative nodes, battles, and branching outcomes.
_Avoid_: Story (internal code term), adventure, run
_Note_: The code uses `StoryDefinition` / `Story` — the player-facing term is Campaign.

## Relationships

- A **Mod** contains one or more **Campaigns**, **Missions**, characters, items, and maps
- A **Campaign** is a sequence of story nodes; **Mission** nodes launch battles
- A **Mission** defines one battle's map, spawned **Units**, **Victory Conditions**, **Failure Conditions**, and **Battle Scripts**; for tiled maps it also names which **Spawn Groups** are active
- A **Character** enters a battle as a **Unit**; if the Unit is killed, the Character is permanently removed from the **Roster** (permadeath)
- **Recruitment** adds a Character to the Roster — either via a **Battle Script** during a Mission or via a story node in a Campaign
- **Campaign State** is written and read by story nodes across a Campaign run
- A **Battle Script** fires when its trigger is met (turn, unit death, interaction) and executes effects against the live battle state
- **Combat** is initiated by one **Unit** attacking another; the defender may **Counterattack** depending on weapon range and effects
- **Deployment** optionally precedes a Mission; the player positions Roster Characters among predefined tiles before the battle begins
- A **Chapter** (narrative) groups story nodes for the player; the **Battle Index** counts completed battles for stats — neither maps directly to the other

## Example dialogue

> **Designer:** "In the second chapter, I want the boss to speak when you attack him, then reinforcements spawn if he survives."
> **Dev:** "So a **Battle Script** with a **BeforeCombat** trigger filtered to the boss unit, with a Dialogue effect followed by a SpawnUnits effect — and one_shot so it only fires once?"
> **Designer:** "Exactly. And if the player recruits the captain unit, I want her added to the roster automatically."
> **Dev:** "That's a **RecruitUnits** script effect — same battle script or a separate one triggered by the captain's death?"
> **Designer:** "Separate — trigger on the captain surviving to end of battle, not dying. And make sure the **campaign state** records that she joined, so a later **campaign** node can reference her name."

## Flagged ambiguities

- **chapter** is used in code for two distinct things: the narrative **Chapter** (player-facing titled section) and the **Battle Index** (internal battle count). Never use "chapter" alone in design discussion — qualify which you mean.
- **neutral** side is displayed as "ally" in some UI — this is a presentation artifact. The canonical side name is `neutral`.
- **Recruitment** currently has two separate code implementations (`RecruitUnits` battle script and `roster_add` story node) — treat them as the same concept in domain discussion.
- **objective** appears in code (`objective.lua`) as an umbrella for victory and failure conditions — prefer **victory condition** / **failure condition** in design discussion, as "objective" misrepresents failure states.

