# DeleteFile Story Node — Design

## Summary

Add a `delete_file` story node that deletes the current save file and immediately advances. Mirrors the shape of `save_game`: silently advances (with a debug log) when no save file is active.

## Changes

### `save_system.delete(name)`

Add a `delete` function to `src/tactics/save/save_system.lua`. Constructs the same path as `save` and calls `rm`. Logs at `log.debug` before deletion.

```lua
function save_system.delete(name)
    local path = SAVE_PATH .. name .. ".pod"
    log.debug("Deleting save: ", name, path)
    rm(path)
end
```

### `Story:handle_new_node` — `'delete_file'` branch

New branch in the if-chain:

- If `self.save_name` is nil: `log.debug("No save file to delete, advancing")` then `self:advance_node()`.
- Otherwise: `log.debug(...)` then `save_system.delete(self.save_name)` then `self:advance_node()`.

Also add a `log.debug` to the existing `save_game` nil branch (currently missing).

### Type annotation

```lua
---@class DeleteFileNode : StoryNode
--- No extra fields — type = 'delete_file' is sufficient.
```

### Test story (`mods/test_base/game_data/stories.lua`)

```lua
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

### Integration test (`src/integration/story/simple_flow_spec.lua`)

```lua
describe("delete_file_and_exit", function()
    it("should complete immediately on start", function()
        local h = story_harness.new()
        h:start_story("delete_file_and_exit")
        luassert.is_true(h:is_complete())
    end)
end)
```

The harness starts stories with `save_name = nil`, so this exercises the silent-advance path. The `save_system.delete` function is straightforward enough that a unit test on the story node integration test is sufficient.
