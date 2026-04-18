# Plan: Generic MenuManager / MenuNode Types

## Goal

Eliminate the `undefined-field` and `param-type-mismatch` LLS errors in
`battle_menu_manager.lua` (and future implementors) by making the menu
type system generic over its two context parameters:

- `TServices` — the `GameContext` subtype (e.g. `BattleMenuContext`)
- `TContext` — the `MenuContext` subtype (e.g. `BattleMainMenuContext`)

This removes the need for per-callback `---@cast` annotations and makes
incorrect context access a compile-time error.

## Background

Three `MenuManager` implementations exist:

| File | TServices | TContext |
|---|---|---|
| `battle_menu_manager.lua` | `BattleMenuContext` | `BattleMainMenuContext` |
| `game_menu_manager.lua` | `GameMenuContext` | `MainMenuContext` |
| `story_menu_manager.lua` | `GameContext` (base) | `StoryMenuContext` |

Callbacks in `grid.lua`, `list.lua`, and `selection.lua` are all typed
against the base types (`GameContext`, `MenuContext`), so LLS cannot see
the subtype fields inside any implementation's inline lambdas.

## Files to Change (annotations only — no logic changes)

### 1. `src/tactics/menu/menu_manager.lua`

- `---@class MenuManager` → `---@class MenuManager<TServices, TContext>`
- `---@alias MenuHandler` → parameterize over `TServices, TContext`
- `MenuStepDefinition.initial_data` callback signature
- `MenuStepDefinition:with_initial_data()` and `:build()` signatures
- `menu_manager.new()` — add `---@generic` so return type is `MenuManager<TServices, TContext>`

### 2. `src/tactics/menu/cursor/nested/grid.lua`

- `NestedGridDefinition`, `NestedGridChildDefinition`, `NestedGridChild`,
  `NestedGridNode` → add `<TServices, TContext>` type params
- All builder method `---@param` annotations for callbacks:
  - `:with_child(filter)` — `fun(p, game_ctx: TServices, menu_ctx: TContext)`
  - `:with_tile_highlights()`, `:with_path_anchor()`, `:with_path_length()`,
    `:with_initial_point()`, `:with_text_function()`

### 3. `src/tactics/menu/cursor/nested/list.lua`

- `NestedMenuDefinition<TServices, TContext>`
- `nested_menu.column()` and `nested_menu.row()` `get_children` callback

### 4. `src/tactics/menu/cursor/selection.lua`

- `SelectionMenuDefinition<TServices, TContext>`
- `:with_options()` callback

### 5. `src/tactics/menu/menu_cursor.lua`

- `MenuNode<TServices, TContext>` — all method fields that take context params:
  `update_joy`, `update_mouse`, `handle_command`, `get_focused_leaves`,
  `recompute`, `to_cursor`
- Standardize parameter order while here — currently inconsistent
  (`game_ctx, menu_ctx` vs `menu_ctx, game_ctx` in different methods)

### 6. Implementation files (3)

In each, type `MENU_DATA` explicitly so the generic params propagate into
the inline lambdas:

```lua
---@type MenuData<BattleMenuContext, BattleMainMenuContext>
local MENU_DATA = { ... }
```

Update `new()` return annotations to the concrete subtype.

## Key Risk: LLS Generic Inference Depth

The propagation chain is:

```
MENU_DATA<TServices, TContext>
  → MenuStepDefinition<TServices, TContext>
    → NestedGridDefinition<TServices, TContext>
      → callback fun(p, game_ctx: TServices, menu_ctx: TContext)
```

LLS handles 1–2 levels of generic inference reliably. Four levels of nested
generic propagation may silently fall back to `unknown`. This is the main
risk and should be validated early.

**Recommended validation step:** Before the full refactor, spike on one
builder method in isolation — annotate `grid.grid()` as returning
`NestedGridBuilder<TServices, TContext>`, type one `MENU_DATA` entry, and
confirm LLS resolves the inner callback parameters to the concrete types.
If it doesn't, the fallback is to `---@cast` just the grid builder result
rather than the whole MENU_DATA table.

## Parameter Order Inconsistency

`menu_cursor.lua` uses `(menu_ctx, game_ctx)` while all other files use
`(game_ctx, menu_ctx)`. Standardize to `(game_ctx, menu_ctx)` as part of
this work (or as a prerequisite cleanup).

## What This Does Not Change

- No runtime behaviour changes — purely annotations
- `MenuHandler` HANDLERS tables in each implementation file do not need
  annotation changes beyond the alias update
- The `MenuContext` and `GameContext` base class definitions are unchanged
