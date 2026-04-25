# Task: Story Config Presets — Data Model

## Goal
Restructure the `StoryConfigDefinition` type and update the `demo_story` mod data to support the new preset format. This is a prerequisite for all other preset tasks.

The current `config` field on `StoryDefinition` is an array alias (`StoryConfigDefinition = StoryConfigDefinitionEntry[]`). It becomes a structured object with `options`, optional `presets`, and optional `default_preset`.

## Files
- `src/tactics/story/types.lua` — update `StoryConfigDefinition` from array alias to class; add `StoryConfigPreset` class; update `StoryDefinition.config` annotation
- `mods/types.d.lua` — update `ModStoriesModule` if `StoryConfigDefinition` is referenced there
- `mods/tt_fantasy_demo_story/game_data/stories.lua` — restructure `demo_story.config` to `{ options = {...}, presets = {...}, default_preset = "normal" }`

## Verification
- `make test` passes (no runtime breakage — the UI step that reads `config` will need updating in task 03, but tests should not exercise that path)
- Types are internally consistent: `StoryConfigDefinition` has `options`, `presets?`, `default_preset?`; `StoryConfigPreset` has `key`, `name`, `values`

## Notes
New types needed:

```lua
---@class StoryConfigDefinition
---@field options StoryConfigDefinitionEntry[]
---@field presets? StoryConfigPreset[]
---@field default_preset? string

---@class StoryConfigPreset
---@field key string
---@field name string
---@field values table<string, string>
```

Preset values for `demo_story` should map `turn_difficulty`, `saving`, and `deaths`. Suggested defaults:
- easy: `turn_difficulty=easy, saving=ironman, deaths=casual`
- normal: `turn_difficulty=normal, saving=ironman, deaths=classic`
- hard: `turn_difficulty=hard, saving=hardcore, deaths=classic`

`default_preset = "normal"`.

The `game_menu_manager.lua` STORY_CONFIG step currently reads `definition.config` as an array — it will break after this task until task 03 updates it. That is acceptable since task 03 follows immediately.
