# Story Integration Tests Design

**Date:** 2026-04-15

## Overview

Add a story flow integration test layer using a system-slice harness. Tests wire up `StoryManager`, `TaskManager`, and `EventBus` directly — no full game loop, no `UIManager`, no `AnimationManager`, no `MusicPlayer`. Assertions focus on stable observable points (node id, story completion, memory values, events) and are deliberately kept general to survive future story node refactors.

---

## File Structure

```
src/integration/
  helpers/
    story_harness.lua       -- StoryHarness class
  story/
    simple_flow_spec.lua    -- first story integration tests
  modloading_spec.lua       -- existing

mods/
  test_base/                -- shared test mod
    mod.lua
    game_data/
      stories.lua
      characters.lua
      items.lua
      maps.lua
      battles.lua
```

Additional test mods can be added to `mods/` for more specific scenarios. Tests that need minor variations define story data inline and pass it as overrides to the harness constructor, which merges them on top of `test_base`.

---

## Production Change: TaskManager.is_idle()

A single small addition to production code: `TaskManager` gains an `is_idle()` method that returns `true` when no coroutines are queued or active. This is the signal the harness uses to know the story has reached a waiting-for-input point.

---

## test_base Mod

The shared test mod provides minimal but realistic content. It has no dependencies on other mods.

**Stories (`game_data/stories.lua`):**

- **`simple_exit`** — a single `exit_story` node. Smoke test baseline; story completes immediately on start.
- **`linear_text`** — 2-3 text nodes ending in `exit_story`. Tests that confirm advances through sequential text nodes.
- **`jump_flow`** — a node that jumps to a non-sequential target node, ending in `exit_story`. Tests that jump routing arrives at the correct node.

**Other content:**
- `characters.lua` — 1-2 minimal characters (for future battle story tests)
- `maps.lua` — 1 minimal map (for future battle story tests)
- `battles.lua` — 1 minimal battle fixture (for future battle story tests)
- `items.lua` — empty

---

## StoryHarness API

```lua
-- Construction
local harness = story_harness.new()
-- uses test_base mod as-is

local harness = story_harness.new({ stories = { ... } })
-- inline story data merged on top of test_base

-- Driving
harness:start_story("simple_exit")
-- loads mod data, creates Story, ticks to idle

harness:confirm()
-- feeds one BUTTON_A press frame, then ticks to idle

harness:dpad(dx, dy)
-- feeds one directional input frame, then ticks to idle

-- Asserting (stable public interface only)
harness:is_complete()         -- true when story has reached exit_story
harness:current_node_id()     -- id of the node the story is currently at
harness:memory(key)           -- reads a StoryMemory value by key
harness:emitted(event_type)   -- returns list of EventBus events of that type
```

**Tick loop:** `tick_to_idle()` is internal. It loops `task_manager:update()` until `task_manager:is_idle()` returns true. A safety cap of 1000 ticks prevents infinite loops from hanging the test suite. Each input method (`confirm`, `dpad`) calls `tick_to_idle()` after feeding input, so tests never manage ticking directly.

**System slice wired up by harness:**
- `StoryManager`
- `TaskManager`
- `EventBus`

No-op stubs (already covered by `picotron_shim.lua` or trivially stubbed):
- Drawing/UI — no-op
- `AnimationManager` — no-op stub
- `MusicPlayer` — no-op (shim already covers this)

---

## Example Tests

```lua
local story_harness = require("src.integration.helpers.story_harness")

describe("story flow #it", function()
    describe("simple_exit", function()
        it("should complete immediately", function()
            local h = story_harness.new()
            h:start_story("simple_exit")
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("linear_text", function()
        it("should advance through text nodes on confirm", function()
            local h = story_harness.new()
            h:start_story("linear_text")
            luassert.is_false(h:is_complete())
            h:confirm()
            h:confirm()
            luassert.is_true(h:is_complete())
        end)
    end)

    describe("jump_flow", function()
        it("should arrive at the jump target node", function()
            local h = story_harness.new()
            h:start_story("jump_flow")
            luassert.are_equal("jump_target", h:current_node_id())
        end)
    end)
end)
```

---

## Future Scope

- Additional test mods for battle-story flows, once the battle slice is ready
- `harness:navigate_to_story(story_id)` shortcut for common menu-driven flows, once menu integration tests are added
- Real demo story smoke tests using the same harness against `tt_fantasy_demo_story`
