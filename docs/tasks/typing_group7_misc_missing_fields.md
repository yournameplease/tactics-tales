---
source_file: src/tactics/battle/combat/combat_calculator.lua
line: 1
todo_text: "fix type errors: misc missing-fields and undefined-field in smaller files"
slug: typing_group7_misc_missing_fields
created: 2026-04-19
---

# Typing Group 7: Misc smaller files — missing-fields and undefined-field (~14 errors)

**Files:**
- `src/tactics/battle/combat/combat_calculator.lua` (~7 errors)
- `src/tactics/animation.lua` (~4 errors)
- `src/tactics/config/config_manager.lua` (~1 error)
- `src/tactics/battle/battle_manager.lua` (~2 errors)

## Error Summary

**combat_calculator.lua:**
- `undefined-field`: `defense_type`, `avoid_type`, `amount` — fields on unioned/unnarrowed defense/avoid types
- `missing-fields`: `CombatPreviewResult` missing `possible_kill`, `possible_self_kill`

**animation.lua:**
- `missing-fields`: `AnimatedSpriteData` missing `current_frame`
- `missing-fields`: `DirectionalOffsetAnimationInstance` missing `get_animation_facing`

**config_manager.lua:**
- `missing-fields`: `DynamicConfig` missing `log_level`, `draw_flexbox_debug`, `draw_target_debug`, `head_scale`, `dialogue_speed`, `input_group`

**battle_manager.lua:**
- `missing-fields`: `UnitSpawnData` missing `movement_side`, `ai`, `tags`
- `undefined-field`: `teardown`

## Pre-Planning Step (do this first)

1. Run `make check 2>&1 | grep -E 'combat_calculator|animation\.lua|config_manager|battle_manager\.lua' | grep -E 'undefined-field|missing-fields'` for current full list
2. For each `missing-fields` error: find the type definition and add the missing fields (or make them optional if appropriate)
3. For `undefined-field` in combat_calculator: find the defense/avoid type and check if subtypes with those fields exist; add `---@as` cast or fix the union
4. For `battle_manager.lua teardown`: find where `teardown` is called and check if it's defined on the object
5. Work each file independently — these are all small and low-risk

## Notes

<!-- Add design notes or user answers here. -->
