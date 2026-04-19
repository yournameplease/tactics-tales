---
source_file: src/tactics/story/story.lua
line: 1
todo_text: "fix type errors: story node discriminated union subtype fields"
slug: typing_group4_story_node_union_fields
created: 2026-04-19
---

# Typing Group 4: story.lua — story node discriminated union fields (~22 errors)

**File:** `src/tactics/story/story.lua`

## Error Summary

`undefined-field` — subtype fields accessed on union-typed story nodes:
- `text`, `chapter_number` — chapter node fields
- `key`, `value`, `name_key` — condition/variable node fields
- `battle_id` — battle node fields
- `template`, `tags` — character/template node fields
- `keyboard_content` — input node field
- `next_node`, `next_node_victory`, `next_node_failure` — branching fields

`missing-fields`:
- `ActiveNode` missing `rendered_node`
- `CharacterAppearance` missing `gender`, `head`, `hair`, `skin`, `hair_color`, `body_class`, `beard`, `eyes`, `eyewear`, `headwear`

## Root Cause

Same pattern as script_manager (Group 3): story nodes are a discriminated union, and the checker can't narrow to the correct subtype at dispatch sites. The `CharacterAppearance` and `ActiveNode` constructor sites also omit required fields.

## Pre-Planning Step (do this first)

1. Run `make check 2>&1 | grep 'story\.lua' | grep -E 'undefined-field|missing-fields'` for current full list
2. Find the story node union type definition
3. For each node variant, check if a subtype with those fields is declared
4. For `CharacterAppearance` and `ActiveNode` missing-fields: find the constructor and add the missing fields (or make them optional if appropriate)
5. Decide: `---@as` casts at dispatch sites, or restructure union narrowing
6. Work the fixes, ask for feedback on approach

## Notes

<!-- Add design notes or user answers here. -->
