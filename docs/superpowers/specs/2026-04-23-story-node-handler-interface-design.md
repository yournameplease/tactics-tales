# Story Node Handler Interface — Design Spec

**Date:** 2026-04-23

## Context

`story.lua` dispatches node behaviour through three large `if-else` chains in `handle_new_node`, `advance_node`, and `update`. Adding a node type requires edits across all three methods, and each method's branches are hard to test in isolation. The goal is to extract each node type's logic into a handler object so the dispatch methods become thin wrappers, and each handler can be understood and tested independently.

## Interface

```lua
---@class StoryNodeHandler
---@field enter fun(story: Story, node: StoryNode)
---@field exit? fun(story: Story, node: StoryNode)   -- nil = no cleanup needed
---@field update? fun(story: Story, input: InputContext) -- nil = no input handling
```

- `enter` — called by `handle_new_node`; sets up rendering and/or fires immediate side effects.
- `exit` — called at the start of `advance_node` before incrementing the step; cleans up rendered state.
- `update` — called by `Story:update` each tick; handles input and triggers `story:advance_node()` when done.

## Shared Helpers

Two local functions extracted at the top of the handlers file, reused across handlers:

```lua
-- Advance when active_dialogue finishes (text, chapter_header, save_game, game_results).
local function dialogue_update(story, input)
    story.dialogue_manager:update(input)
    if story.active_dialogue ~= nil and story.active_dialogue.finished then
        story.active_dialogue = nil
        story:advance_node()
    end
end

-- Update both dialogue and menu (character_customizer, text_input).
local function menu_update(story, input)
    story.dialogue_manager:update(input)
    story.menu_manager:update(input)
end
```

## Node Handler Summary

| Node type | enter | exit | update |
|---|---|---|---|
| `jump` | jump_to_node (no return) | — | — |
| `set_memory` | set + advance | — | — |
| `new_page` | clear_page + advance | — | — |
| `roster_add` | generate + persist + advance | — | — |
| `advance` | advance | — | — |
| `delete_file` | delete + advance | — | — |
| `exit_story` | emit GAME_EXIT_STORY | — | — |
| `chapter_header` | add_chapter_header + create_dialogue | clear_chapter_header | dialogue_update |
| `text` | create_dialogue + add_text_line | finish_text | dialogue_update |
| `save_game` | save (or skip) + create_dialogue | — | dialogue_update |
| `character_customizer` | generate_character + set_menu | persist + set_memory + clear_menu | menu_update |
| `text_input` | set_menu + create_dialogue + add_text_input | set_memory + pop×2 + recreate_dialogue | menu_update |
| `battle` | create battle_manager + clear_page | — | battle_manager:update |
| `game_results` | add_game_results + create_dialogue | — | dialogue_update |

**`game_results` note:** A bare dialogue is created in `enter` to capture the confirm button press (same mechanism as `text`), so `dialogue_update` works unchanged. The page node renders the results content; the dialogue is the advance gate.

**Battle lifecycle:** `handle_battle_victory` and `handle_battle_defeat` remain as `Story` methods. They are invoked by event listeners registered in `story.new`, not by `advance_node`. The battle handler only implements `enter`.

## File Layout

```
src/tactics/story/
  handlers/
    node_handlers.lua   ← single file, all 14 handlers + HANDLERS table
  story.lua             ← dispatch wrappers only
  types.lua             ← unchanged
```

`node_handlers.lua` returns the `HANDLERS` table. `story.lua` requires it and dispatches:

```lua
local HANDLERS = require("src.tactics.story.handlers.node_handlers")

function Story:handle_new_node()
    local node = self.current_node.definition
    local h = assert(HANDLERS[node.type], "Unknown node type: " .. node.type)
    h.enter(self, node)
    self.story_page.story_revision = self.story_page.story_revision + 1
end

function Story:advance_node()
    local node = self.current_node.definition
    local h = HANDLERS[node.type]
    if h.exit then h.exit(self, node) end
    self.current_node.node_step = self.current_node.node_step + 1
    local steps = self:resolve_to_array(self.story_definition.nodes[self.current_node.node_id])
    self.current_node.definition = self:resolve_node_source(steps[self.current_node.node_step])
    self:handle_new_node()
end

function Story:update(input)
    local h = HANDLERS[self.current_node.definition.type]
    if h and h.update then h.update(self, input) end
end
```

## Integration Tests

New spec file: `src/integration/story/node_handler_spec.lua`

One `describe` block per handler category, with representative stories defined inline (as `story_harness.new({ stories = {...} })` overrides):

- **Logic nodes** — `set_memory`, `roster_add`, `delete_file` auto-advance without confirm; memory/roster state is correct after.
- **Dialogue nodes** — `chapter_header`, `text`, `save_game` each require exactly one confirm per node; save_game skips correctly when `save_name` is nil.
- **Menu nodes** — `character_customizer` and `text_input` do not advance on confirm alone; they advance after the menu handler fires (via the existing harness callbacks).
- **game_results** — advances after one confirm; does not advance before.
- **Battle** — covered by existing `battle_flow_spec.lua`; no new cases needed.

Existing tests in `simple_flow_spec.lua` and `battle_flow_spec.lua` must continue to pass unchanged.

## Out of Scope

- Moving handlers to per-file or per-category files (can be done later if the file grows).
- Changing the `StoryNode` data types in `types.lua`.
- Any change to `story_page.lua`, `story_menu_manager.lua`, or the event bus.
