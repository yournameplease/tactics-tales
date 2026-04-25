# Task: Story Config Presets — Selection on_change

## Goal
Add an `on_change` handler hook to the selection widget so that changing a selection can trigger a named handler and cause the menu to re-deserialize. This is the mechanism used by the preset row and individual option rows to keep each other in sync.

## Files
- `src/tactics/menu/cursor/selection.lua` — add `on_change` field to `SelectionMenuDefinition`; add `:with_on_change(handler_id)` builder; emit a new signal when `on_change` is set and selection changes
- `src/tactics/menu/menu_manager.lua` — handle the new signal: call the handler (same `(services, menu_data, session_context, value)` signature as button handlers), then always re-deserialize the menu node from the data returned by the handler

## Verification
- `make test` passes
- Existing selection behaviour (no `on_change`) is unchanged
- A selection with `on_change` set calls the handler after each left/right input and the menu re-deserializes from the returned data

## Notes
New signal type (can be added alongside existing signals in menu_manager.lua or menu_cursor.lua):

```lua
menu_signal.on_change(handler_id, value)
-- type: "on_change", handler: string, value: any
```

In `SelectionMenuNode:update_joy` and `:handle_command`, after `increment_selection` or `decrement_selection`:

```lua
if self.on_change then
    return menu_signal.on_change(self.on_change, self:get_selected_value())
end
return menu_signal.consumed()
```

In `menu_manager.lua`, when processing an `on_change` signal:
1. Call `self.menu_handlers[signal.handler](game_ctx, menu_data, menu_ctx, signal.value)`
2. The handler must return `menu_handler.then_deserialize(data)` — re-deserialize from that data
3. Re-deserialization always happens (unlike regular button handlers where it's optional)

The `on_change` field flows from `SelectionMenuDefinition` to `SelectionMenuNode` via the existing `__index` metatable fallback in `to_cursor`.
