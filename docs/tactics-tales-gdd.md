## Tactics Tales

### What is Tactics Tales?

Tactics Tales is a storybook tactics game that uses procedural generation to construct and link together combat scenarios across a campaign.
The player will follow a hero through a fantasy adventure, recruiting allies along the way.

Once game mechanics are well understood, a player can play a complete story in a few hours,
providing a bite-sized version of inspirational games in the genre, such as Fire Emblem and X-COM (2012), which can take dozens of hours.

### Design Pillars

We give design pillars to ground our goals.

#### Surprise

The player will not know exactly what comes next in the story.

> Oh, no! Enemies are coming from that area!

> I didn't expect the enemies to do that. Now that character is in danger!

> Yes! A new character wants to join! My roster was thin after a tough battle.

<!-- Q: How does this reconcile with simple mechanics?  Does not the player eventually come to expect everything?  The campaign layer and specific battles remain partially unpredictable, at least. -->

#### Tactile

The game is "board-game-like" in that numbers are kept small and easily readable.
Players and enemies will generally have single-digit health and damage numbers to allow for simple mental math.

Simple mechanics and turn options make it easy for a player to understand the state of the battle at a glance.
Moving units is akin to moving a chess piece.
Once abilities are understood, the player can quickly make their actions for the turn.

#### Authorship

The player will at times make decisions impacting the story.
In particular, they will be able to fill in certain words in a Mad-Lib style UI.
Other choices may appear with both gameplay and story implications.

The hero character can be customized.
A player may optionally add custom characters to the pool of random units,
so that their own characters may appear in stories as heroes or villains.

The player should feel as the story is unique to them.

### Audience & Market

The game intends to appeal to fans of tactics games, particularly Fire Emblem,
who want a shorter form-factor in their game.
The game will be reasonably finishable in a single sitting (goal of 1-4 hours, depending on the difficulty and player skill).

Unlike other games in the genre, narrative is *not* a prime focus.
Emergent narrative through a standard fantasy plot exists,
but plot is kept intentionally light to maintain a small scale
and to give space for player choices to feel impactful to the narrative.

The game also intends to appeal to fans of "strategic" roguelikes, such as *FTL: Faster Than Light* and *Slay the Spire*.  The campaign layer is comparable to the map layer of these two games.  The battle layer is different, but will still appeal to this kind of player's tactical sensibilities.  A typical run in this game can exceed an hour, though, unlike the above games.  Configuration settings may be provided to shorten runs to a more manageable time-frame for these players.

### Core Gameplay

Gameplay consists of two "layers":
- A battle layer, where players will face enemies in Fire-Emblem-style combat to achieve some narrative mission.
- A campaign layer, which links together battles in an overarching narrative, while giving the player broad tactical decisions to make.

#### Battle Layer

Battle consists of turns.  Each turn will consist of one phase per combat side: player, then neutral, then enemy.
On a phase, all units of that side may take one action.
An action consists of one movement followed by an optional attack or skill.

Attack initiates a combat.

In general, maps will be a single screen (16x16 tiles).  This keeps the entire battle small and readable.
Certain story-defined missions may have a larger play area and support screen scrolling.

Any player unit which dies in combat will be permanently removed from the player roster.

##### Combat

Combat is one-on-one.
First, the acting unit (attacker) will attack.
If the target (defender) is still alive after the attack, they will counter-attack

Damage is dealt according to the weapon damage and reduced by defenses.
Damage is always at least 1, to limit stall tactics.

Certain weapons will behave differently to encourage diversification and strategy:
- Swords and daggers have no special effects
- Bows attack from range. This avoids melee counterattacks, but means they cannot counterattack melee attacks themself.
- Spears are long-ranged.  They avoid counterattacks, but are still able to counterattack melee weapons.
- Axes and Maces will ignore shields and armor, respectively.

#### Campaign Layer

The campaign layer is themed on a storybook.
Pages of text descriptions, choose-your-own-adventure choices, and mad-lib fill-in-the-blanks.
The battles are the illustrations.

Choices will be given between battles.  These will have different options, each with both narrative and tactical impact.

For example:
- Choose whether to side with one faction or another.
- Choose whether to accept a new character with a past which haunts them (and may lead to a future combat encounter.)
- Allow a character to leave the roster due to personal ties with an enemy. They may appear in a future encounter as a foe.
- Adopt a pet animal who will fight with one of your characters.
- Allow two characters to fall in love. Now the death of one would cause the other to be struck by grief and leave the roster or otherwise suffer penalties.

### Gameplay Balance & Pacing

With short runs, balance does not need to be perfect.
It is expected that some playthroughs will fail,
and others will be easier than usual.

It is important that the player rarely feel they are "out of the running",
as such a player may quit or reset without seeing their story to conclusion.

In serving this goal, frequent boons should be given to the player,
but the payoff of such boons should be limited.
Possible such examples are listed.

- Recruits are frequent, but finite roster space means that strong players cannot run away with a free victory.
- Certain easier missions may appear in the narrative when a player is struggling. \
However, it is important that these feel meaningfully different than standard missions, to not encourage strong players to intentionally weaken their play.
- Spells and abilities can be learned by units.

The game does not feature "leveling up".
Stronger enemies will appear later in the campaign, but these shall be overcome by a well prepared and positioned roster, not from level grinding.

Easier difficulty settings are available for those who prefer a less stressful experience:

- Disable permadeath
- Reduce mission difficulty

### Character Design

Characters must be readable at a glance while still maintaining a unique appearance.
A large head will provide most of the opprotunity for customization.
Different body shapes and clothing are also available.

A player should be able to distinguish their own units, even within the same role,
and grow attachment.

Weapons determine how a player attacks, so they must be large and distinct.
Any equipment or skill must provide some visual element to make it apparent from a glance.
More complex skills may not be immediately understandable from the sprite,
but must still be obvious enough that a player knows to look for detail text.

Each side will have a color palette which is shared by most clothing of the character.
(Blue/Red/Green for Player/Enemy/Neutral. Color blindness settings will be available to change the colors.)

> **CONTINGENT ON FINDING ASSETS OR COMMISSIONING SOMEBODY TO HELP:**
I'm interested in making piecewise profile drawings to mirror the sprites for dialogue boxes, HUDs, etc.
These would be one-color line art of the face at a 3/4 side-profile.

### Tone, Aesthetics, & Setting

The setting is a storybook fantasy.
Lean in to standard tropes of bandits, cultists, wizards, knignts, etc.

The game is lighthearted, despite its focus on permadeath.
The game itself is a storybook, as if the player were being told fairy-tales.
A child listening to fairytales is partly at the mercy of the truth, but will have opprotunity to influence the story.

> **Child:** Did that character escape and live happily ever after?

> **Storyteller:** (*thinking*) *Well, the story doesn't say, so...* Let's see how that plays out.

Evoke the storybook opening to *Paper Mario: The Thousand Year Door*.  Characters and environment decorations are like pop-up book elements.

<!-- insert Paper Mario Title screen screenshot. -->

### Narrative

The campaign layer will contain predefined plot beats
(opening, final battle, and some midway battles)
linked by more generic filler battles.

Each battle will have a brief setup page in the storybook and a brief post-chapter page.
Descriptions will be kept simple, and have multiple variations to ensure the same map feels different on repeat playthroughs.

During this campaign layer, certain parameterized aspects of the battles may be swapped out.
For example, a filler map may feature a different faction of primary antagonists, or modify its unit composition.
Maps may have multiple spawn positions for the player, chosen randomly when the scenario is generated.

Some campaign elements may propose mad-lib responses from the user.  For example:
- Name a stray animal that joins
- Decide what the party eats for dinner
- Describe a character's relationship with another. (?)

These responses have no gameplay impact, but can return in future campaign elements:

- The stray animal's owner is found
- One character particularly loves/hates the food.

### Controls

The game can be played with mouse alone, mouse with keyboard hotkeys, or joypad (including cursor keys).

#### Mouse

Left click must be sufficient for all actions.
Right click may be usable for hotkeys or advanced actions,
but a onscreen button must always exist if the action is necessary.

#### Hotkeys

Tab: Cycle units, targets, etc.
Space: Show/hide additional information.
WSAD: Camera controls, if the map is larger than one screen.

#### Joypad

D-pad or cursor keys navigates through menus or grids.
Primary Button will select, generally mirroring a left click.
Secondary Button will cancel, generally mirroring a right click.

### Technical Details

Simple modding functionality is planned, and used for most campaign, battle, and balancing content.
Exposing this functionality is reasonable but not a high priority.

The game is built in Picotron, which necessitates certain visual elements: 480x270 screen resolution, 32 color palette.

### Business Model

The game will be released in free pre-release versions on itch.io and the Lexaloffle BBS.
During development, the modding API will be unstable.

At release, the game will be released freely on itch.io and the Lexaloffle BBS.
Game code and assets will be released freely with a permissive license.

A paid Steam release is possible.
Steam workshop integration could be added as an incentive for a Steam purchasers.  This would add some scope beyond the 1.0 goal in making the API stable and user-friendly.


<!-- Final Questions: -->
<!-- Q: Does the game really need to be >1 hour?  Can we not keep it at ~1 hour to appeal to  roguelike crowd while remaining interesting for tactics crowd? -->
<!-- Q: Is the mad-lib actually valuable? I find it endearing, but it would need to be configurable / skippable for power players. Tomodachi Life is a new source that inspires me to continue with this concept. -->
<!-- Q: Do I even have a compelling game here? I think... maybe? Should I be sharing the demo in relevant communities to gather feedback? -->
<!-- Q: Do I care about selling this game? Why do I care? -->