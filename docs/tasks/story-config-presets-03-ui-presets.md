# Task: Story Config Presets — STORY_CONFIG UI Step

## Goal
Update the `STORY_CONFIG` menu step to show a preset selector row above the individual option rows, wire up the two-way sync handlers, pre-populate from the default preset, and strip the internal `_preset` key before starting the story.

## Files
- `src/tactics/game/game_menu_manager.lua` — update `STORY_CONFIG` step, add `with_initial_data`, add `apply_preset` and `sync_preset_from_options` handlers, update `begin_file_from_context` to strip `_preset`

## Verification
- `make test` passes
- Manual flow: New Game → file select → STORY_CONFIG
  - Preset row appears at top; default preset is pre-selected; individual options reflect preset values
  - Selecting a different preset snaps all option values
  - Changing an individual option switches preset row to "Custom"
  - Selecting a preset after "Custom" snaps all options back
  - "Begin" starts the story with the correct `StoryConfig` (no `_preset` key)
- Stories with no `config` still work (skip step as before)
- Stories with `config.options` but no `config.presets` show only individual option rows

## Notes

**Reading options:** change `definition.config` → `definition.config.options` (and guard for `definition.config` being nil).

**Initial data provider** (via `step_definition:with_initial_data`):
```lua
function(msb, _ctx)
    local def = msb.stories[msb.default_story_id]
    local config = def and def.config
    if not config or not config.presets or not config.default_preset then return {} end
    local preset_key = config.default_preset
    local data = { _preset = preset_key }
    for _, p in ipairs(config.presets) do
        if p.key == preset_key then
            for k, v in pairs(p.values) do data[k] = v end
        end
    end
    return data
end
```

**Preset row** (prepend before option rows when `config.presets` exists):
```lua
local preset_row = selection.row("_preset")
    :with_key("_preset")
    :with_label("Difficulty")
    :with_on_change("apply_preset")
for _, p in ipairs(config.presets) do
    preset_row = preset_row:with_static_option{ value = p.key, text = p.name }
end
preset_row = preset_row:with_static_option{ value = "custom", text = "Custom" }
table.insert(options, preset_row)
```

**Each option row** gets `:with_on_change("sync_preset_from_options")`.

**`apply_preset` handler:**
```lua
HANDLERS["apply_preset"] = function(services, menu_data, _ctx, value)
    if value == "custom" then
        return menu_handler.then_deserialize(menu_data)
    end
    local config = services.stories[services.default_story_id].config
    local data = { _preset = value }
    for k, v in pairs(menu_data) do data[k] = v end  -- keep existing keys
    for _, p in ipairs(config.presets) do
        if p.key == value then
            for k, v in pairs(p.values) do data[k] = v end
        end
    end
    return menu_handler.then_deserialize(data)
end
```

**`sync_preset_from_options` handler:**
```lua
HANDLERS["sync_preset_from_options"] = function(services, menu_data, _ctx, _value)
    local config = services.stories[services.default_story_id].config
    local matched = "custom"
    if config and config.presets then
        for _, p in ipairs(config.presets) do
            local match = true
            for k, v in pairs(p.values) do
                if menu_data[k] ~= v then match = false; break end
            end
            if match then matched = p.key; break end
        end
    end
    local data = {}
    for k, v in pairs(menu_data) do data[k] = v end
    data._preset = matched
    return menu_handler.then_deserialize(data)
end
```

**Strip `_preset` in `begin_file_from_context`:**
```lua
local config = {}
for k, v in pairs(menu_data) do
    if k ~= "_preset" then config[k] = v end
end
services.handle_begin_story(session_context.selected_file, services.default_story_id, config)
```

`services.stories` is already available on `GameMenuContext` (populated from `game_data.stories.data` in `game.lua`).
