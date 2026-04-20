# DeleteFile Story Node Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `delete_file` story node that deletes the current save file and immediately advances, mirroring the nil-guard pattern of `save_game`.

**Architecture:** `save_system` gets a `delete(name)` function that calls `rm`. `Story:handle_new_node` gets a new `'delete_file'` branch. A test story and integration test cover the silent-advance path (harness always passes `save_name = nil`).

**Tech Stack:** Lua, Busted test runner (`make it` for integration tests, `make ut` for unit tests)

---

### Task 1: Add `save_system.delete` with a unit test

**Files:**
- Modify: `src/tactics/save/save_system.lua`
- Create: `src/spec/save/save_system_spec.lua`

- [ ] **Step 1: Create the failing test**

Create `src/spec/save/save_system_spec.lua`:

```lua
local luassert = require("luassert")
local spy = require("luassert.spy")
local save_system = require("src.tactics.save.save_system")

describe("save_system", function()
    describe("delete", function()
        it("should call rm with the correct path", function()
            local rm_spy = spy.on(_G, "rm")
            save_system.delete("my_save")
            luassert.spy(rm_spy).was_called_with("/appdata/tactics_tales/saves/my_save.pod")
            rm_spy:revert()
        end)
    end)
end)
```

- [ ] **Step 2: Run the test and confirm it fails**

```bash
busted build/spec/save/save_system_spec.lua
```

Expected: FAIL — `attempt to call a nil value (field 'delete')`

- [ ] **Step 3: Implement `save_system.delete`**

In `src/tactics/save/save_system.lua`, add after the `save_system.load` function (before `return save_system`):

```lua
--- Delete the save file for the given slot name.
---@param name string Save slot name.
function save_system.delete(name)
    local path = SAVE_PATH .. name .. ".pod"
    log.debug("Deleting save: ", name, path)
    rm(path)
end
```

- [ ] **Step 4: Run the test and confirm it passes**

```bash
busted build/spec/save/save_system_spec.lua
```

Expected: PASS (1 success)

- [ ] **Step 5: Commit**

```bash
git add src/tactics/save/save_system.lua src/spec/save/save_system_spec.lua
git commit -m "Add save_system.delete and unit test"
```

---

### Task 2: Add `delete_file` node + fix `save_game` nil log

**Files:**
- Modify: `src/tactics/story/story.lua`

- [ ] **Step 1: Add `log.debug` to the `save_game` nil branch**

In `src/tactics/story/story.lua`, find the `save_game` nil-guard (around line 227):

```lua
    elseif node_definition.type == 'save_game' then
        if self.save_name == nil then
            self:advance_node()
```

Replace with:

```lua
    elseif node_definition.type == 'save_game' then
        if self.save_name == nil then
            log.debug("No save file configured, skipping save_game")
            self:advance_node()
```

- [ ] **Step 2: Add the `DeleteFileNode` type annotation**

In `src/tactics/story/story.lua`, add near the other node type annotations (around line 23, alongside `JumpNode`, `SetMemoryNode`, etc.):

```lua
---@class DeleteFileNode : StoryNode
```

- [ ] **Step 3: Add the `delete_file` branch**

In `src/tactics/story/story.lua`, add a new branch in `Story:handle_new_node` after the `save_game` block and before the `else` / `unexpected` line:

```lua
    elseif node_definition.type == 'delete_file' then
        if self.save_name == nil then
            log.debug("No save file configured, skipping delete_file")
        else
            log.debug("Deleting save file: ", self.save_name)
            save_system.delete(self.save_name)
        end
        self:advance_node()
```

- [ ] **Step 4: Run the full unit test suite to confirm nothing broke**

```bash
make ut
```

Expected: all tests pass

- [ ] **Step 5: Commit**

```bash
git add src/tactics/story/story.lua
git commit -m "Add delete_file story node handler and debug log to save_game nil branch"
```

---

### Task 3: Add test story and integration test

**Files:**
- Modify: `mods/test_base/game_data/stories.lua`
- Modify: `src/integration/story/simple_flow_spec.lua`

- [ ] **Step 1: Add the integration test (failing)**

In `src/integration/story/simple_flow_spec.lua`, add a new `describe` block after `advance_and_exit`:

```lua
    describe("delete_file_and_exit", function()
        it("should complete immediately on start", function()
            local h = story_harness.new()
            h:start_story("delete_file_and_exit")
            luassert.is_true(h:is_complete())
        end)
    end)
```

- [ ] **Step 2: Run the integration test and confirm it fails**

```bash
make it
```

Expected: FAIL — `assert game_data.stories.data[story_id] ~= nil` (story not found)

- [ ] **Step 3: Add the test story**

In `mods/test_base/game_data/stories.lua`, add inside the `data` table (e.g. after `advance_and_exit`):

```lua
        -- delete_file node then exit. Tests that delete_file advances without a confirm().
        delete_file_and_exit = {
            starting_node = "main",
            nodes = {
                main = {
                    { type = "delete_file" },
                    { type = "exit_story" },
                },
            },
        },
```

- [ ] **Step 4: Run the integration tests and confirm they pass**

```bash
make it
```

Expected: all integration tests pass, including `delete_file_and_exit`

- [ ] **Step 5: Run the full test suite**

```bash
make test
```

Expected: all tests pass

- [ ] **Step 6: Commit**

```bash
git add mods/test_base/game_data/stories.lua src/integration/story/simple_flow_spec.lua
git commit -m "Add delete_file_and_exit test story and integration test"
```
