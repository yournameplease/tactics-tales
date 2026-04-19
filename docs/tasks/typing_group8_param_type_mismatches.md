---
source_file: src/spec/battle/tactics/ai_engine_spec.lua
line: 1
todo_text: "fix type errors: param-type-mismatch across various files"
slug: typing_group8_param_type_mismatches
created: 2026-04-19
---

# Typing Group 8: param-type-mismatch — various files (~20 errors)

**Files:**
- `src/spec/battle/tactics/ai_engine_spec.lua` (~8 errors)
- `src/spec/systems/event_bus_spec.lua` (~5 errors)
- Various src files (~7 errors)

## Error Summary

**ai_engine_spec.lua:**
- `nil` cannot match `TaskManager` (×8) — test setup not constructing/providing a TaskManager

**event_bus_spec.lua:**
- `"BATTLE_END_VICTORY"` cannot match `"TACTICS_BEGIN_TURN"` (×5) — string literal event name types are overly narrow; spec uses event names that don't match the declared enum

**Other:**
- `MapDefinition` cannot match `StaticMapDefinition` — subtype/variance issue; passing a broader type where a narrower one is expected
- `MenuContext` cannot match `BattleMainMenuContext` (×2) — context narrowing needed at call site
- `userdata` cannot match `number` — Picotron API returns `userdata` where `number` is expected; needs `---@as number` cast or updated Picotron shim type
- `nil` cannot match `BattleUnit` — optional field accessed without nil check
- `nil` cannot match `integer` — similar nil safety issue
- `nil` cannot match `unknown` — untyped variable passed to typed param

## Pre-Planning Step (do this first)

1. Run `make check 2>&1 | grep 'param-type-mismatch'` and correlate with file paths from `errors_by_file.txt` for current full list
2. For `nil` vs `TaskManager` in ai_engine_spec: check how TaskManager is constructed in other specs and replicate
3. For event name literal mismatches: check whether the event type should be widened to `string` or the spec should use the correct event names
4. For `MapDefinition` vs `StaticMapDefinition`: determine if a cast or a type guard is appropriate
5. For `userdata` vs `number`: update the Picotron shim annotation or add `---@as number` at call sites
6. Work each cluster independently, ask for feedback on the event-name approach (widening vs correcting)

## Notes

<!-- Add design notes or user answers here. -->
