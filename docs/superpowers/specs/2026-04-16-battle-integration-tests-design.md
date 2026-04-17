# Battle Integration Tests Design

**Date:** 2026-04-16
**Branch:** initial-integration-testing

## Goal

Add integration tests for battle flow — the turn/phase cycle, objective resolution, and BATTLE_END
emission — at the battle level (BattleHarness), with a small number of story-level tests that cross
the story↔battle boundary.

---

## Background

The existing `StoryHarness` wires `TaskManager + EventBus + AnimationManager + UIContextManager +
MusicPlayer`, loads `test_base` via `mod_loader`, creates a `Story`, and drives it by calling
`tick_to_idle()` after each input frame. The story integration tests exercise the node-execution
pipeline without touching the game's UI or rendering.

The battle system adds `BattleManager`, `TacticsEngine`, `TurnManager`, `AIEngine`,
`BattleObjectiveService`, and `ScriptManager`. The main new obstacle is that
`map_generator.load_static` calls `fetch(DATP .. definition.file)`, and the test shim's `fetch`
currently returns nil.

---

## Approach: fetch interception with mock map data

Rather than adding a new map type, the harness overrides `_G.fetch` to serve a real-looking mock
response (a list of `{name, bmp}` tables) for known test map file paths. `load_static` sees a valid
fetch result and proceeds normally through `as_map`, `apply_checkerboard`, and
`apply_default_walls`. No changes to `map_generator` are needed.

### Shim changes

`fget` and `fset` currently ignore their arguments (`fget` always returns 0, `fset` is a no-op).
`fget_one` is legacy and is removed. All three are replaced with a live backing store:

```lua
local _sprite_flags = {}
fget = function(n)
    return _sprite_flags[n] or 0
end,
fset = function(n, f, val)
    local flags = _sprite_flags[n] or 0
    if val then
        _sprite_flags[n] = flags | (1 << f)
    else
        _sprite_flags[n] = flags & ~(1 << f)
    end
end,
```

`get_terrain` reads `fget(tile_sprite)` to determine the solid bit (0x01) and terrain type bits
(0x02–0x08). With a working `fget`, test maps can express passable and impassable tiles.

### Sprite fixtures

A new fixture module defines canonical test sprite indices and sets their flags once:

```lua
-- src/integration/helpers/sprite_fixtures.lua
M.FLOOR = 1   -- flags 0x00: not solid, terrain type 0 → movement cost 1
M.SOLID = 2   -- flags 0x01: solid bit set → movement cost 999

function M.setup()
    fset(M.FLOOR, 0, false)
    fset(M.SOLID, 0, true)
end
```

`setup()` is idempotent. It is called during harness construction.

### Fetch interceptor

A shared helper manages the override lifetime:

```lua
-- src/integration/helpers/map_fetch_interceptor.lua
function interceptor.new()      -- saves _G.fetch, installs override
function interceptor:register(path, data)
function interceptor:teardown() -- restores original _G.fetch
```

### build_map_fetch

A module-level helper on `battle_harness` constructs the mock fetch response:

```lua
battle_harness.build_map_fetch(width, height, tile_positions)
-- tile_positions: table<metatile_idx, {x, y}[]>
```

The floor layer is filled with `sprite_fixtures.FLOOR` at every tile (passable, cost 1). The
metatile layer has `BASE_METATILE (0x400) + metatile_idx` set at each labeled coordinate. All wall
layers are zero (sprite 0 → `get_terrain` returns nil → treated as cost 999, but only relevant if a
unit tries to enter them, which no unit does in the open test arena).

---

## BattleHarness

**File:** `src/integration/helpers/battle_harness.lua`

### Construction

```lua
local h = battle_harness.new(overrides?)
-- overrides.battles  -- merged into game_data.battles
-- overrides.maps     -- merged into game_data.maps
```

`new()`:
1. Calls `sprite_fixtures.setup()`
2. Creates a `MapFetchInterceptor` and pre-registers `"map/test_arena.map"` with the test_arena
   fetch data
3. Wires services: `TaskManager`, `EventBus`, `AnimationManager`, `UIContextManager`,
   `MusicPlayer`
4. Loads `test_base` via `mod_loader`, merges any overrides
5. Wraps `event_bus:emit` to record all events by type; captures `BATTLE_END` result

### Public API

```lua
h:register_map_fetch(path, fetch_data)  -- register a custom map path
h:start_battle(battle_id)               -- new CharacterManager + BattleManager.new(), tick_to_idle
h:finish_player_turn()                  -- emit TACTICS_FINISH_SIDE_ACTIONS, tick_to_idle
h:tick_to_idle()                        -- drain task manager (1000-tick guard)
h:battle_result()                       -- "VICTORY" | "DEFEAT" | nil
h:emitted(event_type)                   -- list of recorded payloads for that event type
h:teardown()                            -- restores _G.fetch via interceptor
```

`finish_player_turn()` emits `TACTICS_FINISH_SIDE_ACTIONS` directly on the shared EventBus.
`TurnManager` already listens for this event and drives the phase/turn cycle; the harness does not
need to know about `TurnManager` internals.

---

## StoryHarness additions

Two methods are added to the existing `StoryHarness`:

```lua
h:register_map_fetch(path, fetch_data)  -- delegates to a new MapFetchInterceptor
h:finish_player_turn()                  -- emit TACTICS_FINISH_SIDE_ACTIONS, tick_to_idle
```

`StoryHarness.new()` also calls `sprite_fixtures.setup()` and creates a `MapFetchInterceptor`
pre-registered with the test_arena fetch data, so story-level battle tests work without extra
setup.

---

## test_base data additions

### maps.lua

```lua
test_arena = { type = "static", file = "map/test_arena.map" }
-- 16×16 open arena
-- player_spawn: metatile 0x01 at (2, 7)
-- enemy_spawn:  metatile 0x02 at (13, 7)
```

The `BattleHarness` pre-registers the fetch response for `"map/test_arena.map"` encoding these
positions on every construction.

### characters.lua

A `default` template carrying all appearance randomization options (identical to `BASE_UNIT` in
`tt_fantasy_demo_story`) so that `character_generator` can build characters without registering
additional mods. Two test-specific templates inherit from it:

- `test_fighter`: `hp_max = 10`, `movement = 3`, no item_loadout (unarmed — avoids combat
  interactions in initial tests)
- `test_enemy`: `hp_max = 1`, `movement = 2`, no item_loadout

### battles.lua

| id | units | map | victory | failure | notes |
|----|-------|-----|---------|---------|-------|
| `rout_no_enemies` | none | test_arena | rout | none | Rout triggers on first `finish_player_turn()` since 0 enemies always satisfies the condition |
| `rout_with_player` | 1 player (test_fighter) at player_spawn | test_arena | rout | none | Same outcome, player unit present |
| `turn_limit_defeat` | 1 player (test_fighter) at player_spawn | test_arena | none | turn_limit | turn_limit = 1; requires 2× `finish_player_turn()` to reach turn 2 |

Turn limit mechanics: `turn_limit_exceeded = turn_number > turn_limit`. With turn_limit = 1,
`check_objectives` is called with turn = 1 at the end of the first full turn (1 > 1 = false), then
with turn = 2 after the second `finish_player_turn()` triggers `advance_turn` (2 > 1 = true →
DEFEAT).

### stories.lua (addition)

```lua
battle_and_exit = {
    starting_node = "the_battle",
    nodes = {
        the_battle = {
            { type = "battle", battle_id = "rout_no_enemies",
              next_node_victory = "after_victory",
              next_node_failure = "after_defeat" },
        },
        after_victory = { { type = "exit_story" } },
        after_defeat  = { { type = "exit_story" } },
    },
}
```

---

## Test files

### `src/integration/battle/simple_flow_spec.lua` (new)

```
describe("battle flow #it")
  describe("events")
    it: emits TACTICS_BEGIN_BATTLE on start
    it: emits TACTICS_BEGIN_TURN with turn=1 on start
  describe("rout_no_enemies")
    it: battle_result is VICTORY after finish_player_turn
    it: emits BATTLE_END once
    it: BATTLE_END payload has result="VICTORY"
  describe("turn_limit_defeat")
    it: battle not over after one finish_player_turn
    it: battle_result is DEFEAT after two finish_player_turns
    it: BATTLE_END payload has result="DEFEAT"
    it: emits TACTICS_BEGIN_TURN twice (turns 1 and 2) before defeat
```

### `src/integration/story/battle_flow_spec.lua` (new)

```
describe("story battle flow #it")
  describe("battle_and_exit story")
    it: story is not complete before finish_player_turn
    it: story is complete after finish_player_turn (victory path → exit_story)
    it: emits GAME_EXIT_STORY after battle victory
```

---

## File summary

| File | Change |
|------|--------|
| `src/spec/picotron_shim.lua` | Replace `fget`/`fset`/`fget_one` with live backing-store implementation (remove `fget_one`) |
| `src/integration/helpers/sprite_fixtures.lua` | New — defines FLOOR/SOLID sprite constants and `setup()` |
| `src/integration/helpers/map_fetch_interceptor.lua` | New — `fetch` override/restore with path registry |
| `src/integration/helpers/battle_harness.lua` | New — BattleHarness |
| `src/integration/helpers/story_harness.lua` | Add `register_map_fetch`, `finish_player_turn`, interceptor wiring |
| `mods/test_base/game_data/maps.lua` | Add `test_arena` |
| `mods/test_base/game_data/characters.lua` | Add `default`, `test_fighter`, `test_enemy` templates |
| `mods/test_base/game_data/battles.lua` | Add three test battles |
| `mods/test_base/game_data/stories.lua` | Add `battle_and_exit` story |
| `src/integration/battle/simple_flow_spec.lua` | New — battle-level integration tests |
| `src/integration/story/battle_flow_spec.lua` | New — story-level battle tests |
