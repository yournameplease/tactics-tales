# Story Integration Tests Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `StoryHarness` integration test infrastructure that wires up a story system slice and drives it with joypad input, then exercise it against a shared `test_base` mod.

**Architecture:** A system-slice harness (`TaskManager` + `EventBus` + `AnimationManager` + stubs) loads the `test_base` mod and creates a `Story` instance. Tests call `confirm()` / `dpad()` which feed a single-frame `InputContext` to `story:update()` then tick the `TaskManager` to idle. Assertions use stable public points: `is_complete()`, `current_node_id()`, `memory()`, `emitted()`.

**Tech Stack:** Lua, Busted test runner, existing Picotron shim (`src/spec/picotron_shim.lua`), existing `input_helper.lua`

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Modify | `src/tactics/systems/tasks.lua` | Add `TaskManager:is_idle()` |
| Modify | `src/spec/systems/tasks_spec.lua` | Tests for `is_idle()` |
| Create | `mods/test_base/mod.lua` | Test mod spec |
| Create | `mods/test_base/game_data/stories.lua` | Three reusable story skeletons |
| Create | `mods/test_base/game_data/characters.lua` | Empty |
| Create | `mods/test_base/game_data/items.lua` | Empty |
| Create | `mods/test_base/game_data/maps.lua` | Empty |
| Create | `mods/test_base/game_data/battles.lua` | Empty |
| Create | `src/integration/helpers/story_harness.lua` | `StoryHarness` class |
| Create | `src/integration/story/simple_flow_spec.lua` | First integration tests |

---

## Background: How Story Advancement Works

`story:update(input)` is synchronous. With `DYNAMIC_CONFIG.dialogue_speed = "instant"`, a single call with `BUTTON_A.pressed = true` renders all characters and advances the dialogue row in one frame. When dialogue finishes, `advance_node()` is called synchronously, which may chain through auto-advancing node types (jump, new_page, set_memory) before landing at the next input-waiting node. No `TaskManager` coroutines are involved for text/jump/exit_story nodes — `tick_to_idle()` is a correctness guard for future battle-node tests where coroutines run.

The `#it` tag at the end of a `describe` string causes Busted to include that file in `busted src/ --tags='it'` and exclude it from `busted src/ --exclude-tags='it'`. The tag goes on the outermost `describe`.

---

## Task 1: Add `TaskManager:is_idle()`

**Files:**
- Modify: `src/tactics/systems/tasks.lua`
- Modify: `src/spec/systems/tasks_spec.lua`

- [ ] **Step 1: Write three failing tests in `tasks_spec.lua`**

  Append inside the outer `describe("tactics.systems.tasks", ...)` block, after the existing `describe("update_tasks", ...)` block:

  ```lua
      describe("is_idle", function()
          it("should return true when no tasks are queued", function()
              local tm = tasks.task_manager()
              luassert.is_true(tm:is_idle())
          end)

          it("should return false while a task is pending", function()
              local tm = tasks.task_manager()
              tm:start_routine(function() coroutine.yield() end)
              luassert.is_false(tm:is_idle())
          end)

          it("should return true after all tasks run and are cleaned up", function()
              local tm = tasks.task_manager()
              tm:start_routine(function() end)
              tm:update_tasks() -- runs task to completion; task still in list as dead
              tm:update_tasks() -- cleans up dead task
              luassert.is_true(tm:is_idle())
          end)
      end)
  ```

- [ ] **Step 2: Run the tests to confirm they fail**

  ```bash
  busted src/spec/systems/tasks_spec.lua
  ```

  Expected: 3 failures — `attempt to call a nil value (method 'is_idle')`

- [ ] **Step 3: Implement `is_idle()` in `tasks.lua`**

  Add after `TaskManager:update_tasks()`:

  ```lua
  --- Return true when there are no active or pending tasks.
  ---@return boolean
  function TaskManager:is_idle()
      return #self.tasks == 0
  end
  ```

- [ ] **Step 4: Run tests to confirm they pass**

  ```bash
  busted src/spec/systems/tasks_spec.lua
  ```

  Expected: all pass, 0 failures

- [ ] **Step 5: Run full unit test suite to check for regressions**

  ```bash
  busted src/ --exclude-tags='it'
  ```

  Expected: all pass

- [ ] **Step 6: Commit**

  ```bash
  git add src/tactics/systems/tasks.lua src/spec/systems/tasks_spec.lua
  git commit -m "feat: add TaskManager:is_idle() for integration test harness"
  ```

---

## Task 2: Create test_base Mod

**Files:**
- Create: `mods/test_base/mod.lua`
- Create: `mods/test_base/game_data/stories.lua`
- Create: `mods/test_base/game_data/characters.lua`
- Create: `mods/test_base/game_data/items.lua`
- Create: `mods/test_base/game_data/maps.lua`
- Create: `mods/test_base/game_data/battles.lua`

- [ ] **Step 1: Create `mods/test_base/mod.lua`**

  ```lua
  return {
      id = "test_base",
      name = "Test Base",
      description = "Minimal shared mod for integration tests.",
      version = "0.1.0",
      dependendcies = {},
      content = {
          maps       = "game_data/maps",
          battles    = "game_data/battles",
          stories    = "game_data/stories",
          characters = "game_data/characters",
          items      = "game_data/items",
      },
  }
  ```

  Note: `dependendcies` matches the typo used in all existing mods.

- [ ] **Step 2: Create `mods/test_base/game_data/stories.lua`**

  Three story skeletons. Node arrays are step sequences within a node; `advance_node()` increments the step index.

  ```lua
  return {
      data = {
          -- Completes immediately on start. Baseline smoke test.
          simple_exit = {
              starting_node = "exit",
              nodes = {
                  exit = {
                      { type = "exit_story" },
                  },
              },
          },

          -- Two text nodes then exit. Tests that confirm() advances through sequential text.
          linear_text = {
              starting_node = "main",
              nodes = {
                  main = {
                      { type = "text", text = "First line." },
                      { type = "text", text = "Second line." },
                      { type = "exit_story" },
                  },
              },
          },

          -- Jump from start node to a named target. Tests jump routing.
          jump_flow = {
              starting_node = "start",
              nodes = {
                  start = {
                      { type = "jump", next_node = "jump_target" },
                  },
                  jump_target = {
                      { type = "text", text = "You jumped here." },
                      { type = "exit_story" },
                  },
              },
          },
      },
      default_story = "simple_exit",
      story_select  = { "simple_exit", "linear_text", "jump_flow" },
  }
  ```

- [ ] **Step 3: Create empty data files**

  `mods/test_base/game_data/characters.lua`:
  ```lua
  return {}
  ```

  `mods/test_base/game_data/items.lua`:
  ```lua
  return {}
  ```

  `mods/test_base/game_data/maps.lua`:
  ```lua
  return {}
  ```

  `mods/test_base/game_data/battles.lua`:
  ```lua
  return {}
  ```

- [ ] **Step 4: Verify the mod loads via a quick Busted smoke check**

  ```bash
  busted src/integration/modloading_spec.lua
  ```

  Expected: existing tests still pass (this confirms the mod_loader still works and the shim is loaded)

- [ ] **Step 5: Commit**

  ```bash
  git add mods/test_base/
  git commit -m "feat: add test_base mod with simple story skeletons for integration tests"
  ```

---

## Task 3: Write Failing Integration Tests

Write the test file before the harness exists. Busted will error on the `require` line, which counts as a test failure. This establishes the harness API contract before implementation.

**Files:**
- Create: `src/integration/story/simple_flow_spec.lua`

- [ ] **Step 1: Create `src/integration/story/simple_flow_spec.lua`**

  ```lua
  local luassert = require("luassert")
  local story_harness = require("src.integration.helpers.story_harness")

  describe("story flow #it", function()
      describe("simple_exit", function()
          it("should complete immediately on start", function()
              local h = story_harness.new()
              h:start_story("simple_exit")
              luassert.is_true(h:is_complete())
          end)

          it("should emit GAME_EXIT_STORY", function()
              local h = story_harness.new()
              h:start_story("simple_exit")
              luassert.are_equal(1, #h:emitted("GAME_EXIT_STORY"))
          end)
      end)

      describe("linear_text", function()
          it("should not be complete before any confirm", function()
              local h = story_harness.new()
              h:start_story("linear_text")
              luassert.is_false(h:is_complete())
          end)

          it("should not be complete after one confirm", function()
              local h = story_harness.new()
              h:start_story("linear_text")
              h:confirm()
              luassert.is_false(h:is_complete())
          end)

          it("should complete after two confirms", function()
              local h = story_harness.new()
              h:start_story("linear_text")
              h:confirm()
              h:confirm()
              luassert.is_true(h:is_complete())
          end)
      end)

      describe("jump_flow", function()
          it("should land on jump_target after starting", function()
              local h = story_harness.new()
              h:start_story("jump_flow")
              luassert.are_equal("jump_target", h:current_node_id())
          end)

          it("should not be complete before any confirm", function()
              local h = story_harness.new()
              h:start_story("jump_flow")
              luassert.is_false(h:is_complete())
          end)

          it("should complete after one confirm from jump_target", function()
              local h = story_harness.new()
              h:start_story("jump_flow")
              h:confirm()
              luassert.is_true(h:is_complete())
          end)
      end)
  end)
  ```

- [ ] **Step 2: Run integration tests and confirm they fail**

  ```bash
  busted src/ --tags='it'
  ```

  Expected: error on `require("src.integration.helpers.story_harness")` — module not found

- [ ] **Step 3: Commit the failing tests**

  ```bash
  git add src/integration/story/simple_flow_spec.lua
  git commit -m "test: add failing story integration tests (harness not yet implemented)"
  ```

---

## Task 4: Implement StoryHarness

**Files:**
- Create: `src/integration/helpers/story_harness.lua`

**How the harness wires things up:**

`story.new()` requires these arguments:
1. `save_name` — pass `nil` (unsaved story)
2. `story_id` — passed in from `start_story()`
3. `game_data` — from `mod_loader:load_mod_data()` with `test_base` registered
4. `task_manager` — real `tasks.task_manager()`
5. `animation_manager` — real `animation.animation_manager()` (needed for `create_idle_animation()`)
6. `event_bus` — real `event_bus.new()`, monkey-patched to record all emits
7. `music_player` — real `music_player.new()` (shimmed; only used for battle nodes)
8. `ui_context` — real `ui_context_manager.new()` (pure Lua, just a table)

`DYNAMIC_CONFIG.dialogue_speed` is set to `"instant"` so a single `story:update(confirm_input)` both renders all characters and advances the row in one call. This is required for `confirm()` to work in a single update.

`current_node` and `story_memory` are `@field package` in Teal but are plain table fields in compiled Lua — direct access from the Lua harness is fine.

- [ ] **Step 1: Create `src/integration/helpers/story_harness.lua`**

  ```lua
  ---@brief
  --- Test harness for story flow integration tests.
  --- Wires up a system slice (Story + TaskManager + EventBus) and provides
  --- a simple API for driving story flows and asserting on stable outcomes.

  local tasks          = require("src.tactics.systems.tasks")
  local event_bus_mod  = require("src.tactics.systems.event_bus")
  local animation      = require("src.tactics.animation")
  local ui_ctx_mgr     = require("src.tactics.ui.ui_context_manager")
  local music_player_mod = require("src.tactics.music.music_player")
  local mod_loader_mod = require("src.tactics.mods.mod_loader")
  local story_mod      = require("src.tactics.story.story")
  local input_helper   = require("src.spec.input.input_helper")

  local TICK_LIMIT = 1000

  ---@class StoryHarness
  local StoryHarness = {}
  StoryHarness.__index = StoryHarness

  local story_harness = {}

  --- Create a new StoryHarness backed by the test_base mod.
  --- Pass overrides.stories to merge inline story definitions on top of test_base.
  ---@param overrides? { stories?: table<string, any> }
  ---@return StoryHarness
  function story_harness.new(overrides)
      local self = setmetatable({}, StoryHarness)

      -- Instant dialogue speed: one update() renders all chars and advances the row.
      DYNAMIC_CONFIG.dialogue_speed = "instant"

      self._task_manager     = tasks.task_manager()
      self._event_bus        = event_bus_mod.new()
      self._animation_manager = animation.animation_manager()
      self._ui_context       = ui_ctx_mgr.new()
      self._music_player     = music_player_mod.new()

      local loader = mod_loader_mod.new()
      loader:register_mod("test_base")
      self._game_data = loader:load_mod_data()

      if overrides and overrides.stories then
          for id, story_def in pairs(overrides.stories) do
              self._game_data.stories.data[id] = story_def
          end
      end

      self._complete = false
      self._emitted  = {}

      -- Wrap emit to record all events by type.
      local original_emit = self._event_bus.emit
      self._event_bus.emit = function(bus, event_type, args)
          if not self._emitted[event_type] then
              self._emitted[event_type] = {}
          end
          table.insert(self._emitted[event_type], args or {})
          if event_type == "GAME_EXIT_STORY" then
              self._complete = true
          end
          return original_emit(bus, event_type, args)
      end

      self._story = nil
      return self
  end

  --- Create and start the named story, then tick to idle.
  ---@param story_id string
  function StoryHarness:start_story(story_id)
      self._story = story_mod.new(
          nil,
          story_id,
          self._game_data,
          self._task_manager,
          self._animation_manager,
          self._event_bus,
          self._music_player,
          self._ui_context
      )
      self:tick_to_idle()
  end

  --- Loop update_tasks() until the task manager is idle.
  --- Errors after 1000 iterations to catch infinite loops.
  function StoryHarness:tick_to_idle()
      local ticks = 0
      repeat
          self._task_manager:update_tasks()
          ticks = ticks + 1
          if ticks >= TICK_LIMIT then
              error("tick_to_idle: exceeded " .. TICK_LIMIT .. " ticks — possible infinite loop")
          end
      until self._task_manager:is_idle()
  end

  --- Feed one BUTTON_A press frame to the story, then tick to idle.
  function StoryHarness:confirm()
      local input = input_helper.joypad({ a = true, ap = true })
      self._story:update(input)
      self:tick_to_idle()
  end

  --- Feed one directional input frame to the story, then tick to idle.
  ---@param dx integer Horizontal direction (-1, 0, or 1)
  ---@param dy integer Vertical direction (-1, 0, or 1)
  function StoryHarness:dpad(dx, dy)
      local input = input_helper.joypad({ dx = dx, dy = dy, dxp = dx, dyp = dy })
      self._story:update(input)
      self:tick_to_idle()
  end

  --- Return true if the story has reached exit_story.
  ---@return boolean
  function StoryHarness:is_complete()
      return self._complete
  end

  --- Return the node id the story is currently at.
  ---@return string
  function StoryHarness:current_node_id()
      assert(self._story, "start_story() has not been called")
      return self._story.current_node.node_id
  end

  --- Return the StoryMemory entry for key, or nil if not set.
  ---@param key string
  ---@return table?
  function StoryHarness:memory(key)
      assert(self._story, "start_story() has not been called")
      return self._story.story_memory:get(key)
  end

  --- Return all event payloads emitted for the given event type.
  ---@param event_type string
  ---@return table[]
  function StoryHarness:emitted(event_type)
      return self._emitted[event_type] or {}
  end

  return story_harness
  ```

- [ ] **Step 2: Run the integration tests**

  ```bash
  busted src/ --tags='it'
  ```

  Expected: 9 passing tests — 1 existing modloading test + 2 for simple_exit + 3 for linear_text + 3 for jump_flow, 0 failures

- [ ] **Step 3: Run the full test suite to check for regressions**

  ```bash
  busted src/
  ```

  Expected: all tests pass

- [ ] **Step 4: Commit**

  ```bash
  git add src/integration/helpers/story_harness.lua
  git commit -m "feat: implement StoryHarness integration test infrastructure"
  ```
