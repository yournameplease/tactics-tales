## Tactics Tales

### What is Tactics Tales?

Tactics Tales is a storybook tactics game that uses procedural generation to construct and link together combat scenarios across a campaign.
The player will follow a hero through a fantasy adventure, recruiting allies along the way.

Once game mechanics are well understood, a player can play a complete story in a few hours,
providing a bite-sized version of inspirational games in the genre, such as Fire Emblem and X-COM (2012), which can take dozens of hours.

### Design Pillars

We give design pillars to ground our goals. The game is built to support these goals.

#### Surprise

The player will not know exactly what comes next in the story.

> Oh, no! Enemies are coming from that area!

> I didn't expect the enemies to do that.  Now that character is in danger!

> Yes! A new character wants to join! My roster was thin after a tough battle.

#### Tactile

The game is "board-game-like" in that numbers are kept small and easily readable.
Players and enemies will generally have single-digit health and damage numbers to allow for simple mental math.

Simple mechanics and turn options make it easy for a player to understand the state of the battle at a glance.
Moving units is akin to moving a chess piece.
Once abilities are understood, the player can quickly make their actions for the turn.

#### Creation

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

### Core Gameplay

Gameplay consists of two "layers":
- A battle layer, where players will face enemies in Fire-Emblem-style combat to achieve some narrative mission.
- A campaign layer, which links together battles in an overarching narrative, while giving the player broad tactical decisions to make.

#### Battle Layer

In general, maps will be a single screen (tentatively 20x16 tiles).  This keeps the entire battle small and readable.
Certain story-defined missions may have a larger play area and support screen scrolling.

#### Campaign Layer

The campaign layer is themed on a storybook.
Pages of text descriptions, choose-your-own-adventure choices, and mad-lib fill-in-the-blanks.
The battles are the illustrations.

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


### Gameplay Balance & Pacing

With short runs, balance does not need to be perfect.
It is expected that some playthroughs will fail,
and others will be easier than usual.

It is important that the player rarely feel they are "out of the running",
as such a player may quit or reset without seeing their story to conclusion.

In serving this goal, frequent boons should be given to the player,
but only the payoff of such boons should be limited.
Possible such examples are listed.

- Recruits are frequent, but finite roster space means that strong players cannot run away with a free victory.
- Certain easier missions may appear in the narrative when a player is struggling. \
However, it is important that these feel meaningfully different than standard missions, to not encourage strong players to intentionally weaken their play.

### Character Design

Characters must be readable at a glance while still maintaining a unique appearance.
A large head will provide most of the opprotunity for customization.
Different body shapes and clothing are also available.

Weapons determine how a player attacks, so they must be large and distinct.
Any equipment or skill must provide some visual element to make it apparent from a glance.
More complex skills may not be immediately understandable from the sprite,
but must still be obvious enough that a player knows to look for detail text.

Each side will have a color palette which is shared by most clothing of the character.
(Blue/Red/Green for Player/Enemy/Neutral. Color blindness settings will be available to change the colors.)

### Setting & World

The setting is a storybook fantasy.
Lean in to standard tropes of bandits, cultists, wizards, knignts, etc.

### Tone & Aesthetics

The game is lighthearted, despite its focus on permadeath.
The game itself is a storybook, as if the player were being told fairy-tales.
A child listening to fairytales is partly at the mercy of the truth, but will have opprotunity to influence the story.

> Did that character escape and live happily ever after?

> (*thinking*) *Well, the story doesn't say, so...* Let's see how that plays out.

Evoke Paper Mario.  Tactics pieces are pop-up book elements.

<!-- insert Paper Mario Title screen screenshot. -->

### Narrative

The campaign layer will contain predefined plot beats
(opening, final battle, and some midway battles)
linked by more generic filler battles.

Each battle will have a brief setup page in the storybook and a brief post-chapter page.
Descriptions will be kept simple, and have multiple variations to ensure the same map feels different on repeat playthroughs.

During this campaign layer, certain parameterized aspects of the battles may be swapped out.
For example, a filler map may feature a different faction of primary antagonists, or modify its unit composition.

### Business Model

The game will be released in free pre-release versions on itch.io and the Lexaloffle BBS.
During development, the modding API will be unstable.

At release, the game will be released freely on itch.io and the Lexaloffle BBS.
Game code and assets will be released freely with a permissive license.
A paid Steam release is possible.
Steam workshop integration would be added as an incentive for a Steam purchasers.






